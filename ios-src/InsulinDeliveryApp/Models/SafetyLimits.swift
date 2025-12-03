//
//  SafetyLimits.swift
//  InsulinDeliveryApp
//
//  System-wide safety limits and constants
//  IEC 62304 §5.5.2 - Safety requirements implementation
//

import Foundation

/// System-wide safety limits for insulin delivery
/// @safety_critical: These limits are hard-coded to prevent life-threatening errors
/// @requirement: REQ-IDS-100 - System safety limits
struct SafetyLimits {
    
    // MARK: - Glucose Thresholds (mg/dL)
    
    /// Critical low glucose requiring immediate action (< 54 mg/dL)
    static let criticalLowGlucose: Double = 54.0
    
    /// Urgent low glucose alert threshold (< 70 mg/dL)
    static let urgentLowGlucose: Double = 70.0
    
    /// Target low glucose range (80 mg/dL)
    static let targetLowGlucose: Double = 80.0
    
    /// Target high glucose range (180 mg/dL)
    static let targetHighGlucose: Double = 180.0
    
    /// Urgent high glucose alert threshold (> 250 mg/dL)
    static let urgentHighGlucose: Double = 250.0
    
    /// Critical high glucose requiring immediate action (> 400 mg/dL)
    static let criticalHighGlucose: Double = 400.0
    
    // MARK: - Insulin Dosing Limits
    
    /// Minimum insulin dose (0.05 units)
    static let minDose: Double = 0.05
    
    /// Maximum single bolus dose (25 units)
    /// @safety_critical: Doses above this require confirmation
    static let maxSingleDose: Double = 25.0
    
    /// Maximum basal rate (10 units per hour)
    static let maxBasalRate: Double = 10.0
    
    /// Maximum total daily dose (200 units)
    static let maxDailyDose: Double = 200.0
    
    /// Insulin dose increment (0.05 units)
    static let doseIncrement: Double = 0.05
    
    // MARK: - Timing Limits
    
    /// Minimum time between boluses (120 seconds = 2 minutes)
    static let minTimeBetweenBoluses: TimeInterval = 120
    
    /// Maximum insulin action time (8 hours)
    static let maxInsulinActionTime: TimeInterval = 28800
    
    /// Minimum insulin action time (2 hours)
    static let minInsulinActionTime: TimeInterval = 7200
    
    /// Sensor reading timeout (10 minutes)
    static let sensorReadingTimeout: TimeInterval = 600
    
    /// Maximum time for dose delivery (1 hour)
    static let maxDoseDeliveryTime: TimeInterval = 3600
    
    // MARK: - Communication and Sync
    
    /// Maximum time without server communication before forcing sync
    static let maxOfflineTime: TimeInterval = 86400 // 24 hours
    
    /// API request timeout (30 seconds)
    static let apiTimeout: TimeInterval = 30
    
    /// Maximum retry attempts for critical operations
    static let maxRetryAttempts: Int = 3
    
    // MARK: - Session and Security
    
    /// Session timeout requiring re-authentication (15 minutes)
    static let sessionTimeout: TimeInterval = 900
    
    /// Maximum failed login attempts before lockout
    static let maxFailedLoginAttempts: Int = 5
    
    /// Account lockout duration (30 minutes)
    static let accountLockoutDuration: TimeInterval = 1800
    
    // MARK: - Data Validation
    
    /// Minimum valid glucose reading (20 mg/dL)
    static let minValidGlucose: Double = 20.0
    
    /// Maximum valid glucose reading (600 mg/dL)
    static let maxValidGlucose: Double = 600.0
    
    /// Maximum carbohydrate entry (250 grams)
    static let maxCarbEntry: Double = 250.0
    
    // MARK: - Validation Methods
    
    /// Validates a glucose reading is within acceptable sensor range
    static func isValidGlucoseReading(_ value: Double) -> Bool {
        return value >= minValidGlucose && value <= maxValidGlucose
    }
    
    /// Validates an insulin dose is within safety limits
    static func isValidInsulinDose(_ dose: Double) -> Bool {
        return dose >= minDose && dose <= maxSingleDose
    }
    
    /// Validates carbohydrate entry is reasonable
    static func isValidCarbEntry(_ carbs: Double) -> Bool {
        return carbs >= 0 && carbs <= maxCarbEntry
    }
    
    /// Calculates maximum safe bolus based on recent insulin history
    /// @safety_requirement: REQ-IDS-104 - Active insulin consideration
    static func maxSafeBolus(activeInsulin: Double) -> Double {
        let maxAllowed = maxSingleDose - activeInsulin
        return max(0, maxAllowed)
    }
}