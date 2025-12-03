//
//  InsulinDeliveryService.swift
//  InsulinDeliveryApp
//
//  Insulin delivery control and safety validation
//  IEC 62304 §5.6 - Safety-critical insulin delivery
//

import Foundation
import Combine

/// Manages insulin delivery with comprehensive safety checks
/// @safety_critical: This service directly controls insulin delivery - errors can be fatal
class InsulinDeliveryService: ObservableObject {
    
    static let shared = InsulinDeliveryService()
    
    @Published private(set) var activeDelivery: InsulinDose?
    @Published private(set) var deliveryHistory: [InsulinDose] = []
    @Published private(set) var totalDailyInsulin: Double = 0
    @Published private(set) var activeInsulinOnBoard: Double = 0
    
    private var deliveryTimer: Timer?
    private let userProfile: UserProfile?
    private var lastDeliveryTime: Date?
    
    private init() {
        self.userProfile = UserProfileManager.shared.currentProfile
        loadDeliveryHistory()
        startActiveInsulinCalculation()
    }
    
    // MARK: - Dose Delivery
    
    /// Delivers insulin dose with comprehensive safety validation
    /// @safety_requirement: REQ-IDS-109 - Safe insulin delivery with validation
    func deliverDose(_ dose: InsulinDose, 
                    confirmation: @escaping (Bool, String?) -> Void,
                    completion: @escaping (Result<Void, DeliveryError>) -> Void) {
        
        AppLogger.shared.log("Dose delivery requested: \(dose.amount) units, type: \(dose.type.rawValue)",
                           level: .info, category: .delivery)
        
        // SAFETY CHECK 1: Validate dose parameters
        let (valid, reason) = dose.isValid()
        if !valid {
            AppLogger.shared.log("Dose validation failed: \(reason ?? "unknown")",
                               level: .error, category: .delivery)
            completion(.failure(.invalidDose(reason ?? "Dose validation failed")))
            return
        }
        
        // SAFETY CHECK 2: Check minimum time between boluses
        if let lastDelivery = lastDeliveryTime {
            let timeSince = Date().timeIntervalSince(lastDelivery)
            if timeSince < SafetyLimits.minTimeBetweenBoluses {
                let remaining = Int(SafetyLimits.minTimeBetweenBoluses - timeSince)
                completion(.failure(.tooSoonSinceLastDose(remainingSeconds: remaining)))
                return
            }
        }
        
        // SAFETY CHECK 3: Check daily insulin limit
        if totalDailyInsulin + dose.amount > SafetyLimits.maxDailyDose {
            AppLogger.shared.log("Daily insulin limit would be exceeded", level: .error, category: .delivery)
            completion(.failure(.dailyLimitExceeded))
            return
        }
        
        // SAFETY CHECK 4: Check active insulin on board
        let maxSafe = SafetyLimits.maxSafeBolus(activeInsulin: activeInsulinOnBoard)
        if dose.amount > maxSafe {
            completion(.failure(.excessiveActiveInsulin(activeAmount: activeInsulinOnBoard)))
            return
        }
        
        // SAFETY CHECK 5: Require user confirmation for large doses
        if dose.amount >= 10.0 {
            confirmation(true, "Confirm delivery of \(dose.amount) units?") { confirmed in
                if confirmed {
                    self.executeDelivery(dose, completion: completion)
                } else {
                    completion(.failure(.userCancelled))
                }
            }
        } else {
            executeDelivery(dose, completion: completion)
        }
    }
    
    /// Executes the actual insulin delivery
    private func executeDelivery(_ dose: InsulinDose, completion: @escaping (Result<Void, DeliveryError>) -> Void) {
        
        var updatedDose = dose
        updatedDose.status = .delivering
        
        DispatchQueue.main.async {
            self.activeDelivery = updatedDose
        }
        
        AppLogger.shared.log("Executing insulin delivery: \(dose.amount) units",
                           level: .info, category: .delivery)
        
        // Send delivery command to pump via API
        APIClient.shared.deliverInsulin(dose: updatedDose) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Update dose status to completed
                var completedDose = updatedDose
                completedDose.status = .completed
                
                DispatchQueue.main.async {
                    self.activeDelivery = nil
                    self.deliveryHistory.insert(completedDose, at: 0)
                    self.totalDailyInsulin += dose.amount
                    self.lastDeliveryTime = Date()
                }
                
                // Store delivery record
                DataSyncManager.shared.storeInsulinDose(completedDose)
                
                AppLogger.shared.log("Insulin delivery completed: \(dose.amount) units",
                                   level: .info, category: .delivery)
                
                completion(.success(()))
                
            case .failure(let error):
                // Update dose status to failed
                var failedDose = updatedDose
                failedDose.status = .failed
                
                DispatchQueue.main.async {
                    self.activeDelivery = nil
                    self.deliveryHistory.insert(failedDose, at: 0)
                }
                
                AppLogger.shared.log("Insulin delivery failed: \(error.localizedDescription)",
                                   level: .error, category: .delivery)
                
                completion(.failure(.deliveryFailed(error)))
            }
        }
    }
    
    /// Cancels active insulin delivery
    /// @safety_requirement: REQ-IDS-110 - Emergency dose cancellation
    func cancelActiveDelivery(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let active = activeDelivery else {
            completion(.failure(DeliveryError.noActiveDelivery))
            return
        }
        
        AppLogger.shared.log("Cancelling active insulin delivery", level: .warning, category: .delivery)
        
        APIClient.shared.cancelInsulinDelivery(doseId: active.id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                var cancelledDose = active
                cancelledDose.status = .cancelled
                
                DispatchQueue.main.async {
                    self.activeDelivery = nil
                    self.deliveryHistory.insert(cancelledDose, at: 0)
                }
                
                completion(.success(()))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Active Insulin Calculation
    
    private func startActiveInsulinCalculation() {
        // Recalculate active insulin every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.calculateActiveInsulin()
        }
        
        // Calculate immediately
        calculateActiveInsulin()
    }
    
    /// Calculates insulin on board using exponential decay model
    /// @safety_requirement: REQ-IDS-111 - Active insulin tracking
    private func calculateActiveInsulin() {
        guard let profile = userProfile else {
            activeInsulinOnBoard = 0
            return
        }
        
        let actionTime = profile.insulinActionTime
        let now = Date()
        var totalActive: Double = 0
        
        // Calculate active insulin from recent doses
        for dose in deliveryHistory where dose.status == .completed {
            let timeSince = now.timeIntervalSince(dose.timestamp)
            
            // Only consider doses within insulin action time
            if timeSince < actionTime {
                // Exponential decay model
                let fractionActive = 1 - (timeSince / actionTime)
                totalActive += dose.amount * fractionActive
            }
        }
        
        DispatchQueue.main.async {
            self.activeInsulinOnBoard = max(0, totalActive)
        }
    }
    
    // MARK: - History Management
    
    private func loadDeliveryHistory() {
        // Load from local storage
        if let history = DataSyncManager.shared.loadInsulinHistory() {
            deliveryHistory = history
            calculateDailyTotal()
        }
    }
    
    private func calculateDailyTotal() {
        let midnight = Calendar.current.startOfDay(for: Date())
        let todaysDoses = deliveryHistory.filter { 
            $0.timestamp >= midnight && $0.status == .completed 
        }
        totalDailyInsulin = todaysDoses.reduce(0) { $0 + $1.amount }
    }
    
    /// Returns delivery history for specified time period
    func getDeliveryHistory(hours: Int) -> [InsulinDose] {
        let cutoff = Date().addingTimeInterval(TimeInterval(-hours * 3600))
        return deliveryHistory.filter { $0.timestamp > cutoff }
    }
}

// MARK: - Delivery Errors

enum DeliveryError: LocalizedError {
    case invalidDose(String)
    case tooSoonSinceLastDose(remainingSeconds: Int)
    case dailyLimitExceeded
    case excessiveActiveInsulin(activeAmount: Double)
    case userCancelled
    case deliveryFailed(Error)
    case noActiveDelivery
    
    var errorDescription: String? {
        switch self {
        case .invalidDose(let reason):
            return "Invalid dose: \(reason)"
        case .tooSoonSinceLastDose(let remaining):
            return "Please wait \(remaining) seconds before next dose"
        case .dailyLimitExceeded:
            return "Daily insulin limit would be exceeded"
        case .excessiveActiveInsulin(let active):
            return "Too much active insulin on board: \(String(format: "%.2f", active)) units"
        case .userCancelled:
            return "Delivery cancelled by user"
        case .deliveryFailed(let error):
            return "Delivery failed: \(error.localizedDescription)"
        case .noActiveDelivery:
            return "No active delivery to cancel"
        }
    }
}