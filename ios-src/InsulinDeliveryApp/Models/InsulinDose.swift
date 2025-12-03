//
//  InsulinDose.swift
//  InsulinDeliveryApp
//
//  Model representing an insulin dose delivery
//  IEC 62304 §5.5.3 - Safety-critical data structure
//

import Foundation

/// Represents an insulin dose to be delivered or that has been delivered
/// @safety_critical: Incorrect dosing can result in patient harm or death
struct InsulinDose: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let amount: Double // Units of insulin
    let type: DoseType
    let status: DoseStatus
    let calculationMethod: CalculationMethod
    let associatedGlucose: Double? // mg/dL at time of dose
    let carbAmount: Double? // grams of carbohydrates
    let notes: String?
    
    /// Type of insulin dose
    enum DoseType: String, Codable {
        case basal = "Basal"           // Continuous background insulin
        case bolus = "Bolus"           // Mealtime insulin
        case correction = "Correction" // Corrective dose for high glucose
        case combo = "Combination"     // Combined bolus + correction
    }
    
    /// Status of dose delivery
    enum DoseStatus: String, Codable {
        case pending = "Pending"
        case delivering = "Delivering"
        case completed = "Completed"
        case cancelled = "Cancelled"
        case failed = "Failed"
    }
    
    /// Method used to calculate dose
    enum CalculationMethod: String, Codable {
        case manual = "Manual Entry"
        case calculator = "Bolus Calculator"
        case automated = "Automated"
    }
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         amount: Double,
         type: DoseType,
         status: DoseStatus = .pending,
         calculationMethod: CalculationMethod,
         associatedGlucose: Double? = nil,
         carbAmount: Double? = nil,
         notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.type = type
        self.status = status
        self.calculationMethod = calculationMethod
        self.associatedGlucose = associatedGlucose
        self.carbAmount = carbAmount
        self.notes = notes
    }
    
    /// Validates dose is within safety limits
    /// @safety_requirement: REQ-IDS-102 - Dose validation
    func isValid() -> (valid: Bool, reason: String?) {
        // Check maximum single dose
        if amount > SafetyLimits.maxSingleDose {
            return (false, "Dose exceeds maximum single dose of \(SafetyLimits.maxSingleDose) units")
        }
        
        // Check minimum dose
        if amount < SafetyLimits.minDose && amount > 0 {
            return (false, "Dose below minimum of \(SafetyLimits.minDose) units")
        }
        
        // Check dose increment
        let remainder = amount.truncatingRemainder(dividingBy: SafetyLimits.doseIncrement)
        if remainder > 0.001 { // Allow for floating point precision
            return (false, "Dose must be in increments of \(SafetyLimits.doseIncrement) units")
        }
        
        return (true, nil)
    }
    
    /// Returns estimated delivery time in minutes
    var estimatedDeliveryTime: Double {
        // Assume delivery rate of 1 unit per minute (typical for most pumps)
        return amount / 1.0
    }
}