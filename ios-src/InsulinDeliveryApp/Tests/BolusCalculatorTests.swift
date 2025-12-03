//
//  BolusCalculatorTests.swift
//  InsulinDeliveryAppTests
//
//  Unit tests for bolus calculator
//  IEC 62304 §5.7 - Safety-critical algorithm testing
//

import XCTest
@testable import InsulinDeliveryApp

class BolusCalculatorTests: XCTestCase {
    
    var testProfile: UserProfile!
    
    override func setUp() {
        super.setUp()
        
        // Create test user profile with known parameters
        testProfile = UserProfile(
            userId: "test123",
            firstName: "Test",
            lastName: "Patient",
            dateOfBirth: Date(),
            diagnosisDate: Date(),
            insulinCarbRatio: 10.0,        // 1 unit per 10g carbs
            insulinSensitivityFactor: 50.0, // 1 unit drops glucose by 50 mg/dL
            targetGlucose: 100.0,
            targetGlucoseRange: 80...120,
            basalRateSchedule: [],
            maxBasalRate: 2.0,
            maxBolusAmount: 20.0,
            maxDailyInsulin: 100.0,
            insulinActionTime: 14400, // 4 hours
            lowGlucoseAlert: 70.0,
            highGlucoseAlert: 180.0,
            urgentLowGlucoseAlert: 55.0,
            glucoseUnit: .mgdL,
            enablePredictiveAlerts: true,
            enableVibration: true,
            notificationSound: "default"
        )
    }
    
    // MARK: - Basic Calculation Tests
    
    func testCarbOnlyCalculation() {
        // Test calculation for meal without correction
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 100,
            carbAmount: 50,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.carbDose, 5.0, accuracy: 0.01) // 50g / 10 = 5 units
        XCTAssertEqual(result.correctionDose, 0, accuracy: 0.01)
        XCTAssertEqual(result.totalRecommended, 5.0, accuracy: 0.01)
    }
    
    func testCorrectionOnlyCalculation() {
        // Test correction dose for high glucose
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 200,
            carbAmount: 0,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.carbDose, 0, accuracy: 0.01)
        XCTAssertEqual(result.correctionDose, 2.0, accuracy: 0.01) // (200-100) / 50 = 2 units
        XCTAssertEqual(result.totalRecommended, 2.0, accuracy: 0.01)
    }
    
    func testCombinedCalculation() {
        // Test meal + correction
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 200,
            carbAmount: 50,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.carbDose, 5.0, accuracy: 0.01)
        XCTAssertEqual(result.correctionDose, 2.0, accuracy: 0.01)
        XCTAssertEqual(result.totalRecommended, 7.0, accuracy: 0.01)
    }
    
    // MARK: - Active Insulin Tests
    
    func testActiveInsulinReduction() {
        // Test that active insulin reduces recommendation
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 200,
            carbAmount: 50,
            profile: testProfile,
            activeInsulin: 3.0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.totalRecommended, 4.0, accuracy: 0.01) // 7.0 - 3.0 = 4.0
    }
    
    func testExcessiveActiveInsulin() {
        // Test that excessive active insulin results in zero recommendation
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 150,
            carbAmount: 20,
            profile: testProfile,
            activeInsulin: 10.0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.totalRecommended, 0, accuracy: 0.01)
        XCTAssertFalse(result.warnings.isEmpty)
    }
    
    // MARK: - Safety Limit Tests
    
    func testMaximumDoseCapping() {
        // Test that dose is capped at personal maximum
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 400,
            carbAmount: 200,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.totalRecommended, testProfile.maxBolusAmount)
        XCTAssertFalse(result.warnings.isEmpty)
    }
    
    func testLowGlucoseWarning() {
        // Test warning for low glucose
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 60,
            carbAmount: 50,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.warnings.isEmpty)
        XCTAssertTrue(result.warnings.first?.contains("low") ?? false)
    }
    
    func testInvalidGlucoseReading() {
        // Test invalid glucose reading
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 700,
            carbAmount: 50,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
    }
    
    func testInvalidCarbAmount() {
        // Test invalid carb amount
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 120,
            carbAmount: 300,
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
    }
    
    // MARK: - Dose Increment Tests
    
    func testDoseIncrement() {
        // Test that dose is rounded to proper increment
        let result = BolusCalculator.calculateBolus(
            currentGlucose: 110,
            carbAmount: 17, // Should result in 1.7 units, rounded to 1.70
            profile: testProfile,
            activeInsulin: 0
        )
        
        XCTAssertTrue(result.isValid)
        // Verify dose is multiple of 0.05
        let remainder = result.totalRecommended.truncatingRemainder(dividingBy: SafetyLimits.doseIncrement)
        XCTAssertEqual(remainder, 0, accuracy: 0.001)
    }
}