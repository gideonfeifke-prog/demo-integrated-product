//
//  GlucoseReading.swift
//  InsulinDeliveryApp
//
//  Model representing a glucose measurement reading
//  IEC 62304 §5.5.3 - Data item definition
//

import Foundation

/// Represents a single glucose reading from the continuous glucose monitor
/// @safety_critical: This data is used for insulin dosing decisions
struct GlucoseReading: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let value: Double // mg/dL
    let trend: GlucoseTrend
    let isCalibrated: Bool
    let sensorAge: TimeInterval // seconds
    
    /// Glucose trend direction for predictive alerts
    enum GlucoseTrend: String, Codable {
        case rapidlyRising = "⇈"      // >2 mg/dL/min
        case rising = "↑"             // 1-2 mg/dL/min
        case slowlyRising = "↗"       // 0.5-1 mg/dL/min
        case stable = "→"             // -0.5 to 0.5 mg/dL/min
        case slowlyFalling = "↘"      // -1 to -0.5 mg/dL/min
        case falling = "↓"            // -2 to -1 mg/dL/min
        case rapidlyFalling = "⇊"     // <-2 mg/dL/min
        case unknown = "?"
    }
    
    init(id: UUID = UUID(), 
         timestamp: Date, 
         value: Double, 
         trend: GlucoseTrend = .unknown,
         isCalibrated: Bool = true,
         sensorAge: TimeInterval = 0) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.trend = trend
        self.isCalibrated = isCalibrated
        self.sensorAge = sensorAge
    }
    
    /// Determines if glucose level is in critical range
    /// @safety_requirement: REQ-IDS-101 - Critical glucose level detection
    var isCritical: Bool {
        return value < SafetyLimits.criticalLowGlucose || value > SafetyLimits.criticalHighGlucose
    }
    
    /// Determines if glucose level requires immediate attention
    var requiresImmediateAttention: Bool {
        return value < SafetyLimits.urgentLowGlucose || 
               value > SafetyLimits.urgentHighGlucose ||
               (trend == .rapidlyFalling && value < SafetyLimits.targetLowGlucose) ||
               (trend == .rapidlyRising && value > SafetyLimits.targetHighGlucose)
    }
    
    /// Returns human-readable description of glucose status
    var statusDescription: String {
        switch value {
        case ..<SafetyLimits.criticalLowGlucose:
            return "Critical Low"
        case SafetyLimits.criticalLowGlucose..<SafetyLimits.targetLowGlucose:
            return "Low"
        case SafetyLimits.targetLowGlucose...SafetyLimits.targetHighGlucose:
            return "In Range"
        case SafetyLimits.targetHighGlucose..<SafetyLimits.criticalHighGlucose:
            return "High"
        default:
            return "Critical High"
        }
    }
}