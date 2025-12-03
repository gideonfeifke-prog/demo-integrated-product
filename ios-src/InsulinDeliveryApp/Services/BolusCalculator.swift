//
//  BolusCalculator.swift
//  InsulinDeliveryApp
//
//  Bolus insulin calculation for meals and corrections
//  IEC 62304 §5.5 - Safety-critical calculation algorithm
//

import Foundation

/// Calculates insulin bolus doses based on glucose, carbs, and therapy settings
/// @safety_critical: Incorrect calculations can lead to dangerous hypo/hyperglycemia
class BolusCalculator {
    
    /// Calculates recommended bolus dose
    /// @safety_requirement: REQ-IDS-112 - Accurate bolus calculation
    /// @param currentGlucose: Current blood glucose in mg/dL
    /// @param carbAmount: Grams of carbohydrates being consumed
    /// @param profile: User's therapy settings
    /// @param activeInsulin: Current insulin on board in units
    /// @returns: Calculation result with detailed breakdown
    static func calculateBolus(
        currentGlucose: Double,
        carbAmount: Double,
        profile: UserProfile,
        activeInsulin: Double
    ) -> BolusCalculation {
        
        AppLogger.shared.log("Calculating bolus: glucose=\(currentGlucose), carbs=\(carbAmount), IOB=\(activeInsulin)",
                           level: .info, category: .calculation)
        
        // Validate inputs
        var warnings: [String] = []
        var errors: [String] = []
        
        // Validate glucose reading
        if !SafetyLimits.isValidGlucoseReading(currentGlucose) {
            errors.append("Invalid glucose reading: \(currentGlucose) mg/dL")
        }
        
        // Validate carb entry
        if !SafetyLimits.isValidCarbEntry(carbAmount) {
            errors.append("Invalid carbohydrate amount: \(carbAmount)g")
        }
        
        // Check for low glucose
        if currentGlucose < SafetyLimits.urgentLowGlucose {
            warnings.append("⚠️ Glucose is low. Consider treating hypoglycemia before eating.")
        }
        
        // Return error result if validation failed
        guard errors.isEmpty else {
            return BolusCalculation(
                recommendedDose: 0,
                carbDose: 0,
                correctionDose: 0,
                activeInsulinAdjustment: 0,
                totalRecommended: 0,
                isValid: false,
                warnings: warnings,
                errors: errors
            )
        }
        
        // STEP 1: Calculate insulin needed for carbohydrates
        let carbDose = carbAmount / profile.insulinCarbRatio
        
        AppLogger.shared.log("Carb dose: \(carbDose) units (\(carbAmount)g ÷ \(profile.insulinCarbRatio))",
                           level: .debug, category: .calculation)
        
        // STEP 2: Calculate correction dose for high glucose
        var correctionDose: Double = 0
        if currentGlucose > profile.targetGlucose {
            let glucoseAboveTarget = currentGlucose - profile.targetGlucose
            correctionDose = glucoseAboveTarget / profile.insulinSensitivityFactor
            
            AppLogger.shared.log("Correction dose: \(correctionDose) units (\(glucoseAboveTarget)mg/dL ÷ \(profile.insulinSensitivityFactor))",
                               level: .debug, category: .calculation)
        }
        
        // STEP 3: Adjust for active insulin on board
        let activeInsulinAdjustment = -activeInsulin
        
        AppLogger.shared.log("Active insulin adjustment: \(activeInsulinAdjustment) units",
                           level: .debug, category: .calculation)
        
        // STEP 4: Calculate total recommended dose
        var totalRecommended = carbDose + correctionDose + activeInsulinAdjustment
        
        // SAFETY: Never recommend negative dose
        if totalRecommended < 0 {
            warnings.append("⚠️ Active insulin exceeds calculated need. Consider waiting or reducing dose.")
            totalRecommended = 0
        }
        
        // SAFETY: Round to nearest dose increment
        totalRecommended = round(totalRecommended / SafetyLimits.doseIncrement) * SafetyLimits.doseIncrement
        
        // SAFETY: Cap at maximum single dose
        if totalRecommended > profile.maxBolusAmount {
            warnings.append("⚠️ Calculated dose exceeds personal maximum. Capped at \(profile.maxBolusAmount) units.")
            totalRecommended = profile.maxBolusAmount
        }
        
        // Additional warnings
        if totalRecommended > 15.0 {
            warnings.append("⚠️ Large dose calculated. Please verify carb count and glucose reading.")
        }
        
        if currentGlucose < profile.targetGlucoseRange.lowerBound && carbAmount == 0 {
            warnings.append("⚠️ Glucose below target with no carbs. Correction dose not recommended.")
            totalRecommended = 0
        }
        
        AppLogger.shared.log("Final recommended dose: \(totalRecommended) units",
                           level: .info, category: .calculation)
        
        return BolusCalculation(
            recommendedDose: totalRecommended,
            carbDose: carbDose,
            correctionDose: correctionDose,
            activeInsulinAdjustment: activeInsulinAdjustment,
            totalRecommended: totalRecommended,
            isValid: true,
            warnings: warnings,
            errors: errors
        )
    }
}

/// Result of bolus calculation with detailed breakdown
struct BolusCalculation {
    let recommendedDose: Double
    let carbDose: Double
    let correctionDose: Double
    let activeInsulinAdjustment: Double
    let totalRecommended: Double
    let isValid: Bool
    let warnings: [String]
    let errors: [String]
    
    /// Returns formatted breakdown for display
    var formattedBreakdown: String {
        var breakdown = ""
        breakdown += "Carbohydrate Insulin: \(String(format: "%.2f", carbDose)) units\n"
        if correctionDose > 0 {
            breakdown += "Correction Insulin: \(String(format: "%.2f", correctionDose)) units\n"
        }
        if activeInsulinAdjustment < 0 {
            breakdown += "Active Insulin: \(String(format: "%.2f", activeInsulinAdjustment)) units\n"
        }
        breakdown += "━━━━━━━━━━━━━━━━\n"
        breakdown += "Total Recommended: \(String(format: "%.2f", totalRecommended)) units"
        return breakdown
    }
}