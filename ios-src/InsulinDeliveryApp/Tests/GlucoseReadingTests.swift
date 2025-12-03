//
//  GlucoseReadingTests.swift
//  InsulinDeliveryAppTests
//
//  Unit tests for glucose reading model
//  IEC 62304 §5.7 - Data model testing
//

import XCTest
@testable import InsulinDeliveryApp

class GlucoseReadingTests: XCTestCase {
    
    func testCriticalLowDetection() {
        let reading = GlucoseReading(
            timestamp: Date(),
            value: 50,
            trend: .stable
        )
        
        XCTAssertTrue(reading.isCritical)
        XCTAssertTrue(reading.requiresImmediateAttention)
        XCTAssertEqual(reading.statusDescription, "Critical Low")
    }
    
    func testCriticalHighDetection() {
        let reading = GlucoseReading(
            timestamp: Date(),
            value: 450,
            trend: .stable
        )
        
        XCTAssertTrue(reading.isCritical)
        XCTAssertTrue(reading.requiresImmediateAttention)
        XCTAssertEqual(reading.statusDescription, "Critical High")
    }
    
    func testInRangeReading() {
        let reading = GlucoseReading(
            timestamp: Date(),
            value: 120,
            trend: .stable
        )
        
        XCTAssertFalse(reading.isCritical)
        XCTAssertFalse(reading.requiresImmediateAttention)
        XCTAssertEqual(reading.statusDescription, "In Range")
    }
    
    func testRapidlyFallingAlert() {
        let reading = GlucoseReading(
            timestamp: Date(),
            value: 100,
            trend: .rapidlyFalling
        )
        
        XCTAssertTrue(reading.requiresImmediateAttention)
    }
    
    func testRapidlyRisingAlert() {
        let reading = GlucoseReading(
            timestamp: Date(),
            value: 200,
            trend: .rapidlyRising
        )
        
        XCTAssertTrue(reading.requiresImmediateAttention)
    }
}