//
//  SafetyLimitsTests.swift
//  InsulinDeliveryAppTests
//
//  Unit tests for safety-critical limits
//  IEC 62304 §5.7 - Software unit testing
//

import XCTest
@testable import InsulinDeliveryApp

class SafetyLimitsTests: XCTestCase {
    
    // MARK: - Glucose Validation Tests
    
    func testValidGlucoseReading() {
        // Test valid glucose readings
        XCTAssertTrue(SafetyLimits.isValidGlucoseReading(70))
        XCTAssertTrue(SafetyLimits.isValidGlucoseReading(120))
        XCTAssertTrue(SafetyLimits.isValidGlucoseReading(200))
        XCTAssertTrue(SafetyLimits.isValidGlucoseReading(400))
    }
    
    func testInvalidGlucoseReading() {
        // Test invalid glucose readings
        XCTAssertFalse(SafetyLimits.isValidGlucoseReading(10))
        XCTAssertFalse(SafetyLimits.isValidGlucoseReading(700))
        XCTAssertFalse(SafetyLimits.isValidGlucoseReading(-50))
    }
    
    func testGlucoseBoundaries() {
        // Test boundary values
        XCTAssertTrue(SafetyLimits.isValidGlucoseReading(SafetyLimits.minValidGlucose))
        XCTAssertTrue(SafetyLimits.isValidGlucoseReading(SafetyLimits.maxValidGlucose))
        XCTAssertFalse(SafetyLimits.isValidGlucoseReading(SafetyLimits.minValidGlucose - 1))
        XCTAssertFalse(SafetyLimits.isValidGlucoseReading(SafetyLimits.maxValidGlucose + 1))
    }
    
    // MARK: - Insulin Dose Validation Tests
    
    func testValidInsulinDose() {
        // Test valid doses
        XCTAssertTrue(SafetyLimits.isValidInsulinDose(0.5))
        XCTAssertTrue(SafetyLimits.isValidInsulinDose(5.0))
        XCTAssertTrue(SafetyLimits.isValidInsulinDose(15.0))
        XCTAssertTrue(SafetyLimits.isValidInsulinDose(25.0))
    }
    
    func testInvalidInsulinDose() {
        // Test invalid doses
        XCTAssertFalse(SafetyLimits.isValidInsulinDose(0.01)) // Below minimum
        XCTAssertFalse(SafetyLimits.isValidInsulinDose(30.0)) // Above maximum
        XCTAssertFalse(SafetyLimits.isValidInsulinDose(-5.0)) // Negative
    }
    
    func testMaxSafeBolus() {
        // Test with no active insulin
        XCTAssertEqual(SafetyLimits.maxSafeBolus(activeInsulin: 0), 25.0)
        
        // Test with some active insulin
        XCTAssertEqual(SafetyLimits.maxSafeBolus(activeInsulin: 5.0), 20.0)
        
        // Test with high active insulin
        XCTAssertEqual(SafetyLimits.maxSafeBolus(activeInsulin: 20.0), 5.0)
        
        // Test with excessive active insulin (should return 0)
        XCTAssertEqual(SafetyLimits.maxSafeBolus(activeInsulin: 30.0), 0)
    }
    
    // MARK: - Carb Validation Tests
    
    func testValidCarbEntry() {
        XCTAssertTrue(SafetyLimits.isValidCarbEntry(0))
        XCTAssertTrue(SafetyLimits.isValidCarbEntry(50))
        XCTAssertTrue(SafetyLimits.isValidCarbEntry(250))
    }
    
    func testInvalidCarbEntry() {
        XCTAssertFalse(SafetyLimits.isValidCarbEntry(-10))
        XCTAssertFalse(SafetyLimits.isValidCarbEntry(300))
    }
}