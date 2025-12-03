//
//  UserProfile.swift
//  InsulinDeliveryApp
//
//  Patient profile with therapy settings
//  IEC 62304 §5.5.3 - User configuration data
//

import Foundation

/// Contains patient-specific therapy settings and profile information
/// @safety_critical: These settings directly affect insulin dosing
struct UserProfile: Codable {
    var userId: String
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var diagnosisDate: Date
    
    // Therapy Settings - Must be set by healthcare provider
    var insulinCarbRatio: Double        // grams of carbs per unit of insulin
    var insulinSensitivityFactor: Double // mg/dL drop per unit of insulin (ISF)
    var targetGlucose: Double           // mg/dL target glucose
    var targetGlucoseRange: ClosedRange<Double> // mg/dL acceptable range
    
    // Basal Rate Profile
    var basalRateSchedule: [BasalRateSegment]
    
    // Safety Limits (can be more restrictive than system limits)
    var maxBasalRate: Double           // units per hour
    var maxBolusAmount: Double         // units
    var maxDailyInsulin: Double        // units per day
    
    // Active Insulin Time (Duration of Insulin Action)
    var insulinActionTime: TimeInterval // seconds (typically 3-6 hours)
    
    // Alert Settings
    var lowGlucoseAlert: Double        // mg/dL
    var highGlucoseAlert: Double       // mg/dL
    var urgentLowGlucoseAlert: Double  // mg/dL
    
    // Preferences
    var glucoseUnit: GlucoseUnit
    var enablePredictiveAlerts: Bool
    var enableVibration: Bool
    var notificationSound: String
    
    enum GlucoseUnit: String, Codable {
        case mgdL = "mg/dL"
        case mmolL = "mmol/L"
    }
    
    /// Represents a time segment with specific basal rate
    struct BasalRateSegment: Codable {
        let startTime: TimeInterval // seconds from midnight
        let rate: Double           // units per hour
        let name: String           // e.g., "Sleep", "Wake", "Work"
    }
    
    /// Validates that therapy settings are within acceptable ranges
    /// @safety_requirement: REQ-IDS-103 - Therapy settings validation
    func validate() -> (valid: Bool, errors: [String]) {
        var errors: [String] = []
        
        // Validate insulin-to-carb ratio
        if insulinCarbRatio < 1 || insulinCarbRatio > 150 {
            errors.append("Insulin-to-carb ratio must be between 1 and 150")
        }
        
        // Validate insulin sensitivity factor
        if insulinSensitivityFactor < 10 || insulinSensitivityFactor > 500 {
            errors.append("Insulin sensitivity factor must be between 10 and 500 mg/dL")
        }
        
        // Validate target glucose
        if targetGlucose < 70 || targetGlucose > 180 {
            errors.append("Target glucose must be between 70 and 180 mg/dL")
        }
        
        // Validate basal rates
        for segment in basalRateSchedule {
            if segment.rate < 0 || segment.rate > maxBasalRate {
                errors.append("Basal rate in segment '\(segment.name)' exceeds limits")
            }
        }
        
        // Validate max bolus against system limit
        if maxBolusAmount > SafetyLimits.maxSingleDose {
            errors.append("Max bolus amount exceeds system safety limit")
        }
        
        // Validate alert thresholds
        if urgentLowGlucoseAlert >= lowGlucoseAlert {
            errors.append("Urgent low alert must be less than low alert threshold")
        }
        
        if lowGlucoseAlert >= targetGlucoseRange.lowerBound {
            errors.append("Low alert must be less than target range")
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Returns the basal rate for a given time
    func basalRate(at time: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let secondsFromMidnight = TimeInterval((components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60)
        
        // Find the appropriate basal rate segment
        let sortedSegments = basalRateSchedule.sorted { $0.startTime < $1.startTime }
        
        for i in (0..<sortedSegments.count).reversed() {
            if secondsFromMidnight >= sortedSegments[i].startTime {
                return sortedSegments[i].rate
            }
        }
        
        // Return last segment if before first segment (wraps from midnight)
        return sortedSegments.last?.rate ?? 0
    }
}