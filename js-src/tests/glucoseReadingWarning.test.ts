/**
 * Unit tests for Glucose Reading Warning Module
 * 
 * Tests the safety-critical glucose reading validation logic
 * Ensures proper detection of outdated sensor readings
 * 
 * @tests:spec-glucose-reading-warning
 * @itemId:test-glucose-reading-warning
 */

import {
  checkGlucoseReadingWarning,
  triggerGlucoseReadingWarningNotification,
  checkAllWarnings,
  DEFAULT_MAX_READING_AGE_MINUTES,
  GlucoseReading
} from '../app/glucoseReadingWarning';

describe('Glucose Reading Warning System @tests:KD-3', () => {
  describe('checkGlucoseReadingWarning', () => {
    it('should return no warning for recent reading', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 5 * 60 * 1000), // 5 minutes ago
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading);
      expect(result.hasWarning).toBe(false);
      expect(result.isOutdated).toBe(false);
    });

    it('should return warning when reading is outdated', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 20 * 60 * 1000), // 20 minutes ago
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading);
      expect(result.hasWarning).toBe(true);
      expect(result.isOutdated).toBe(true);
      expect(result.ageInMinutes).toBeGreaterThan(DEFAULT_MAX_READING_AGE_MINUTES);
      expect(result.message).toContain('outdated');
    });

    it('should return warning when no reading is provided', () => {
      const result = checkGlucoseReadingWarning(null);
      expect(result.hasWarning).toBe(true);
      expect(result.isOutdated).toBe(true);
      expect(result.message).toContain('No glucose reading available');
    });

    it('should work with custom max age', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 25 * 60 * 1000), // 25 minutes ago
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading, 30); // 30 minute max age
      expect(result.hasWarning).toBe(false);
      expect(result.isOutdated).toBe(false);
    });

    it('should detect readings at exact max age boundary', () => {
      const maxAge = 15;
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - maxAge * 60 * 1000),
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading, maxAge);
      expect(result.hasWarning).toBe(false); // At exactly max age should be acceptable
    });

    it('should detect readings just past max age boundary', () => {
      const maxAge = 15;
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - (maxAge * 60 * 1000 + 1000)), // 1 second past
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading, maxAge);
      expect(result.hasWarning).toBe(true);
      expect(result.isOutdated).toBe(true);
    });

    it('should handle readings from the future (clock sync issue)', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes in future
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading);
      expect(result.hasWarning).toBe(true);
      expect(result.message).toContain('future');
    });

    it('should throw error for invalid glucose value', () => {
      const reading: GlucoseReading = {
        value: NaN,
        timestamp: new Date(),
        source: 'SENSOR'
      };
      
      expect(() => checkGlucoseReadingWarning(reading)).toThrow('Invalid glucose reading value');
    });

    it('should throw error for negative glucose value', () => {
      const reading: GlucoseReading = {
        value: -50,
        timestamp: new Date(),
        source: 'SENSOR'
      };
      
      expect(() => checkGlucoseReadingWarning(reading)).toThrow('Invalid glucose reading value');
    });

    it('should throw error for invalid timestamp', () => {
      const reading: any = {
        value: 120,
        timestamp: 'invalid date',
        source: 'SENSOR'
      };
      
      expect(() => checkGlucoseReadingWarning(reading)).toThrow('Invalid glucose reading timestamp');
    });

    it('should throw error for invalid max age', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(),
        source: 'SENSOR'
      };
      
      expect(() => checkGlucoseReadingWarning(reading, -5)).toThrow('Invalid max age');
    });

    it('should handle manual readings same as sensor readings', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 5 * 60 * 1000),
        source: 'MANUAL'
      };
      
      const result = checkGlucoseReadingWarning(reading);
      expect(result.hasWarning).toBe(false);
    });

    it('should work with custom current time for testing', () => {
      const fixedTime = new Date('2024-01-01T12:00:00Z');
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date('2024-01-01T11:40:00Z'), // 20 minutes before fixed time
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading, 15, fixedTime);
      expect(result.hasWarning).toBe(true);
      expect(result.isOutdated).toBe(true);
      expect(result.ageInMinutes).toBe(20);
    });
  });

  describe('triggerGlucoseReadingWarningNotification', () => {
    it('should return null when there is no warning', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 5 * 60 * 1000),
        source: 'SENSOR'
      };
      
      const warningResult = checkGlucoseReadingWarning(reading);
      const notification = triggerGlucoseReadingWarningNotification(warningResult);
      expect(notification).toBeNull();
    });

    it('should return warning message for outdated reading', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 20 * 60 * 1000),
        source: 'SENSOR'
      };
      
      const warningResult = checkGlucoseReadingWarning(reading);
      const notification = triggerGlucoseReadingWarningNotification(warningResult);
      expect(notification).toBeTruthy();
      expect(notification).toContain('outdated');
    });

    it('should return warning message for missing reading', () => {
      const warningResult = checkGlucoseReadingWarning(null);
      const notification = triggerGlucoseReadingWarningNotification(warningResult);
      expect(notification).toBeTruthy();
      expect(notification).toContain('No glucose reading available');
    });
  });

  describe('checkAllWarnings - Integrated System', () => {
    it('should return no warnings when both reading and dose are valid', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 5 * 60 * 1000),
        source: 'SENSOR'
      };
      
      const warnings = checkAllWarnings(reading, 10.0, { upperLimit: 50, lowerLimit: 0.5 });
      expect(warnings).toHaveLength(0);
    });

    it('should return both warnings when reading is outdated and dose is too high', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 20 * 60 * 1000),
        source: 'SENSOR'
      };
      
      const warnings = checkAllWarnings(reading, 60.0, { upperLimit: 50, lowerLimit: 0.5 });
      expect(warnings).toHaveLength(2);
      expect(warnings[0]).toContain('outdated');
      expect(warnings[1]).toContain('exceeds the safe upper limit');
    });

    it('should return only dose warning when reading is valid but dose is too low', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 5 * 60 * 1000),
        source: 'SENSOR'
      };
      
      const warnings = checkAllWarnings(reading, 0.2, { upperLimit: 50, lowerLimit: 0.5 });
      expect(warnings).toHaveLength(1);
      expect(warnings[0]).toContain('below the effective lower limit');
    });

    it('should return only reading warning when dose is valid but reading is missing', () => {
      const warnings = checkAllWarnings(null, 10.0, { upperLimit: 50, lowerLimit: 0.5 });
      expect(warnings).toHaveLength(1);
      expect(warnings[0]).toContain('No glucose reading available');
    });
  });

  describe('Safety-critical scenarios', () => {
    it('should prevent insulin dosing with very old readings', () => {
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date(Date.now() - 60 * 60 * 1000), // 1 hour old
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading);
      expect(result.hasWarning).toBe(true);
      expect(result.isOutdated).toBe(true);
    });

    it('should handle edge case of reading at exactly midnight', () => {
      const midnight = new Date('2024-01-01T00:00:00Z');
      const reading: GlucoseReading = {
        value: 120,
        timestamp: new Date('2023-12-31T23:50:00Z'),
        source: 'SENSOR'
      };
      
      const result = checkGlucoseReadingWarning(reading, 15, midnight);
      expect(result.ageInMinutes).toBe(10);
      expect(result.hasWarning).toBe(false);
    });
  });
});
