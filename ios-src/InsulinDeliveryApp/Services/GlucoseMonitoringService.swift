//
//  GlucoseMonitoringService.swift
//  InsulinDeliveryApp
//
//  Real-time glucose monitoring and alert management
//  IEC 62304 §5.6 - Safety-critical service
//

import Foundation
import Combine

/// Manages continuous glucose monitoring and critical alerts
/// @safety_critical: Timely glucose monitoring is essential for patient safety
class GlucoseMonitoringService: ObservableObject {
    
    static let shared = GlucoseMonitoringService()
    
    @Published private(set) var currentReading: GlucoseReading?
    @Published private(set) var readingHistory: [GlucoseReading] = []
    @Published private(set) var isConnected: Bool = false
    
    private var monitoringTimer: Timer?
    private var lastReadingTime: Date?
    private let alertManager = AlertManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Monitoring Setup
    
    private func setupMonitoring() {
        // Start polling for glucose readings every 5 minutes
        startContinuousMonitoring()
        
        // Monitor connection status
        monitorConnectionStatus()
    }
    
    /// Starts continuous glucose monitoring
    /// @safety_requirement: REQ-IDS-107 - Continuous glucose monitoring
    func startContinuousMonitoring() {
        AppLogger.shared.log("Starting continuous glucose monitoring", level: .info, category: .monitoring)
        
        monitoringTimer?.invalidate()
        
        // Fetch immediately
        fetchLatestReading()
        
        // Then fetch every 5 minutes (typical CGM interval)
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetchLatestReading()
        }
    }
    
    func stopMonitoring() {
        AppLogger.shared.log("Stopping glucose monitoring", level: .info, category: .monitoring)
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Data Fetching
    
    private func fetchLatestReading() {
        APIClient.shared.fetchLatestGlucoseReading { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let reading):
                self.processNewReading(reading)
                
            case .failure(let error):
                AppLogger.shared.log("Failed to fetch glucose reading: \(error.localizedDescription)",
                                   level: .error, category: .monitoring)
                self.handleReadingTimeout()
            }
        }
    }
    
    /// Processes new glucose reading and triggers alerts if needed
    /// @safety_requirement: REQ-IDS-108 - Glucose alert processing
    private func processNewReading(_ reading: GlucoseReading) {
        // Validate reading
        guard SafetyLimits.isValidGlucoseReading(reading.value) else {
            AppLogger.shared.log("Invalid glucose reading received: \(reading.value)",
                               level: .error, category: .monitoring)
            return
        }
        
        // Update current reading
        DispatchQueue.main.async {
            self.currentReading = reading
            self.lastReadingTime = reading.timestamp
            self.isConnected = true
            
            // Add to history
            self.readingHistory.append(reading)
            
            // Keep only last 24 hours of readings
            let cutoffTime = Date().addingTimeInterval(-86400)
            self.readingHistory = self.readingHistory.filter { $0.timestamp > cutoffTime }
        }
        
        AppLogger.shared.log("Glucose reading: \(reading.value) mg/dL, trend: \(reading.trend.rawValue)",
                           level: .info, category: .monitoring)
        
        // Check for alerts
        checkForAlerts(reading: reading)
        
        // Store reading locally
        DataSyncManager.shared.storeGlucoseReading(reading)
    }
    
    // MARK: - Alert Management
    
    private func checkForAlerts(reading: GlucoseReading) {
        // Critical low glucose
        if reading.value < SafetyLimits.criticalLowGlucose {
            alertManager.triggerCriticalAlert(
                title: "CRITICAL LOW GLUCOSE",
                message: "Glucose is \(Int(reading.value)) mg/dL. Take fast-acting carbs immediately!",
                type: .criticalLow
            )
        }
        // Critical high glucose
        else if reading.value > SafetyLimits.criticalHighGlucose {
            alertManager.triggerCriticalAlert(
                title: "CRITICAL HIGH GLUCOSE",
                message: "Glucose is \(Int(reading.value)) mg/dL. Check for ketones and contact provider.",
                type: .criticalHigh
            )
        }
        // Urgent low glucose
        else if reading.value < SafetyLimits.urgentLowGlucose {
            alertManager.triggerAlert(
                title: "Low Glucose",
                message: "Glucose is \(Int(reading.value)) mg/dL. Consider taking carbs.",
                type: .urgentLow
            )
        }
        // Urgent high glucose
        else if reading.value > SafetyLimits.urgentHighGlucose {
            alertManager.triggerAlert(
                title: "High Glucose",
                message: "Glucose is \(Int(reading.value)) mg/dL. Consider correction dose.",
                type: .urgentHigh
            )
        }
        // Predictive alerts for rapid trends
        else if reading.trend == .rapidlyFalling && reading.value < SafetyLimits.targetLowGlucose + 30 {
            alertManager.triggerAlert(
                title: "Glucose Falling Rapidly",
                message: "Current: \(Int(reading.value)) mg/dL \(reading.trend.rawValue). May drop low soon.",
                type: .predictiveLow
            )
        }
    }
    
    // MARK: - Connection Monitoring
    
    private func monitorConnectionStatus() {
        // Check for reading timeout every minute
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkReadingTimeout()
        }
    }
    
    private func checkReadingTimeout() {
        guard let lastReading = lastReadingTime else { return }
        
        let timeSinceLastReading = Date().timeIntervalSince(lastReading)
        
        if timeSinceLastReading > SafetyLimits.sensorReadingTimeout {
            handleReadingTimeout()
        }
    }
    
    private func handleReadingTimeout() {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        
        AppLogger.shared.log("Glucose sensor connection lost", level: .error, category: .monitoring)
        
        alertManager.triggerAlert(
            title: "Sensor Connection Lost",
            message: "No glucose readings received. Check sensor connection.",
            type: .connectionLost
        )
    }
    
    // MARK: - Historical Data
    
    /// Returns glucose readings for specified time period
    func getReadings(for hours: Int) -> [GlucoseReading] {
        let cutoff = Date().addingTimeInterval(TimeInterval(-hours * 3600))
        return readingHistory.filter { $0.timestamp > cutoff }
    }
    
    /// Calculates time in range for specified period
    func calculateTimeInRange(hours: Int) -> (inRange: Double, low: Double, high: Double) {
        let readings = getReadings(for: hours)
        guard !readings.isEmpty else { return (0, 0, 0) }
        
        let total = Double(readings.count)
        let inRange = Double(readings.filter { 
            $0.value >= SafetyLimits.targetLowGlucose && $0.value <= SafetyLimits.targetHighGlucose 
        }.count)
        let low = Double(readings.filter { $0.value < SafetyLimits.targetLowGlucose }.count)
        let high = Double(readings.filter { $0.value > SafetyLimits.targetHighGlucose }.count)
        
        return (
            (inRange / total) * 100,
            (low / total) * 100,
            (high / total) * 100
        )
    }
}