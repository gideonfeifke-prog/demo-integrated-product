//
//  DataSyncManager.swift
//  InsulinDeliveryApp
//
//  Offline data storage and synchronization
//  IEC 62304 §5.6 - Data management and persistence
//

import Foundation

/// Manages local data storage and synchronization with backend
/// @safety_requirement: REQ-IDS-115 - Reliable data persistence
class DataSyncManager {
    
    static let shared = DataSyncManager()
    
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private var syncTimer: Timer?
    
    private init() {}
    
    func initialize() {
        setupAutoSync()
    }
    
    private func setupAutoSync() {
        // Sync every 15 minutes when online
        syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            self?.performBackgroundSync { _ in }
        }
    }
    
    func performBackgroundSync(completion: @escaping (Result<Void, Error>) -> Void) {
        AppLogger.shared.log("Starting background sync", level: .info, category: .dataSync)
        
        // Upload pending data
        uploadPendingData { result in
            switch result {
            case .success:
                // Download latest data
                self.downloadLatestData { downloadResult in
                    completion(downloadResult)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func performFinalSync() {
        // Synchronous final sync before app termination
        AppLogger.shared.log("Performing final sync before termination", 
                           level: .info, category: .dataSync)
        // Implementation would include synchronous upload of critical data
    }
    
    // MARK: - Glucose Data Storage
    
    func storeGlucoseReading(_ reading: GlucoseReading) {
        var readings = loadGlucoseReadings() ?? []
        readings.append(reading)
        
        // Keep only last 30 days
        let cutoff = Date().addingTimeInterval(-2592000)
        readings = readings.filter { $0.timestamp > cutoff }
        
        if let encoded = try? JSONEncoder().encode(readings) {
            defaults.set(encoded, forKey: "glucoseReadings")
        }
    }
    
    func loadGlucoseReadings() -> [GlucoseReading]? {
        guard let data = defaults.data(forKey: "glucoseReadings"),
              let readings = try? JSONDecoder().decode([GlucoseReading].self, from: data) else {
            return nil
        }
        return readings
    }
    
    // MARK: - Insulin Delivery Storage
    
    func storeInsulinDose(_ dose: InsulinDose) {
        var doses = loadInsulinHistory() ?? []
        doses.insert(dose, at: 0)
        
        // Keep only last 90 days
        let cutoff = Date().addingTimeInterval(-7776000)
        doses = doses.filter { $0.timestamp > cutoff }
        
        if let encoded = try? JSONEncoder().encode(doses) {
            defaults.set(encoded, forKey: "insulinDoses")
        }
    }
    
    func loadInsulinHistory() -> [InsulinDose]? {
        guard let data = defaults.data(forKey: "insulinDoses"),
              let doses = try? JSONDecoder().decode([InsulinDose].self, from: data) else {
            return nil
        }
        return doses
    }
    
    // MARK: - Sync Operations
    
    private func uploadPendingData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Implementation would upload locally stored data that hasn't been synced
        completion(.success(()))
    }
    
    private func downloadLatestData(completion: @escaping (Result<Void, Error>) -> Void) {
        // Implementation would download latest data from server
        completion(.success(()))
    }
}

// MARK: - Supporting Classes

class SecurityManager {
    static let shared = SecurityManager()
    func initialize() {
        AppLogger.shared.log("Security manager initialized", level: .info, category: .security)
    }
}

class UserProfileManager {
    static let shared = UserProfileManager()
    var currentProfile: UserProfile?
}