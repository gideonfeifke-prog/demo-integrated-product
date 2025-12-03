/**
 * Unit tests for Insulin Dose Warning Module
 * 
 * Tests the safety-critical insulin dose validation logic
 * Ensures proper warning detection for doses exceeding safe limits
 * 
 * @tests:spec-insulin-dose-warning
 * @itemId:test-insulin-dose-warning
 */

import {
  checkInsulinDoseWarning,
  triggerInsulinDoseWarningNotification,
  DEFAULT_DOSE_LIMITS,
  InsulinDoseLimits
} from '../app/insulinDoseWarning';

describe('Insulin Dose Warning System @tests:KD-3', () => {
  describe('checkInsulinDoseWarning', () => {
    it('should return no warning for dose within safe limits', () => {
      const result = checkInsulinDoseWarning(10.0);
      expect(result.hasWarning).toBe(false);
      expect(result.dose).toBe(10.0);
    });

    it('should return warning when dose exceeds upper limit', () => {
      const result = checkInsulinDoseWarning(60.0);
      expect(result.hasWarning).toBe(true);
      expect(result.warningType).toBe('DOSE_TOO_HIGH');
      expect(result.dose).toBe(60.0);
      expect(result.limit).toBe(DEFAULT_DOSE_LIMITS.upperLimit);
      expect(result.message).toContain('exceeds the safe upper limit');
    });

    it('should return warning when dose is below lower limit', () => {
      const result = checkInsulinDoseWarning(0.3);
      expect(result.hasWarning).toBe(true);
      expect(result.warningType).toBe('DOSE_TOO_LOW');
      expect(result.dose).toBe(0.3);
      expect(result.limit).toBe(DEFAULT_DOSE_LIMITS.lowerLimit);
      expect(result.message).toContain('below the effective lower limit');
    });

    it('should accept exact upper limit dose without warning', () => {
      const result = checkInsulinDoseWarning(DEFAULT_DOSE_LIMITS.upperLimit);
      expect(result.hasWarning).toBe(false);
    });

    it('should accept exact lower limit dose without warning', () => {
      const result = checkInsulinDoseWarning(DEFAULT_DOSE_LIMITS.lowerLimit);
      expect(result.hasWarning).toBe(false);
    });

    it('should work with custom dose limits', () => {
      const customLimits: InsulinDoseLimits = {
        upperLimit: 30.0,
        lowerLimit: 1.0
      };
      
      const resultHigh = checkInsulinDoseWarning(35.0, customLimits);
      expect(resultHigh.hasWarning).toBe(true);
      expect(resultHigh.warningType).toBe('DOSE_TOO_HIGH');
      
      const resultLow = checkInsulinDoseWarning(0.8, customLimits);
      expect(resultLow.hasWarning).toBe(true);
      expect(resultLow.warningType).toBe('DOSE_TOO_LOW');
    });

    it('should throw error for negative dose', () => {
      expect(() => checkInsulinDoseWarning(-5.0)).toThrow('Invalid insulin dose');
    });

    it('should throw error for NaN dose', () => {
      expect(() => checkInsulinDoseWarning(NaN)).toThrow('Invalid insulin dose');
    });

    it('should throw error for invalid string dose', () => {
      expect(() => checkInsulinDoseWarning('10' as any)).toThrow('Invalid insulin dose');
    });

    it('should throw error when upper limit is not greater than lower limit', () => {
      const invalidLimits: InsulinDoseLimits = {
        upperLimit: 5.0,
        lowerLimit: 10.0
      };
      expect(() => checkInsulinDoseWarning(7.0, invalidLimits)).toThrow('Invalid dose limits');
    });

    it('should handle zero dose (edge case)', () => {
      const result = checkInsulinDoseWarning(0);
      expect(result.hasWarning).toBe(true);
      expect(result.warningType).toBe('DOSE_TOO_LOW');
    });

    it('should handle very large doses correctly', () => {
      const result = checkInsulinDoseWarning(1000.0);
      expect(result.hasWarning).toBe(true);
      expect(result.warningType).toBe('DOSE_TOO_HIGH');
    });
  });

  describe('triggerInsulinDoseWarningNotification', () => {
    it('should return null when there is no warning', () => {
      const warningResult = checkInsulinDoseWarning(10.0);
      const notification = triggerInsulinDoseWarningNotification(warningResult);
      expect(notification).toBeNull();
    });

    it('should return warning message when dose is too high', () => {
      const warningResult = checkInsulinDoseWarning(60.0);
      const notification = triggerInsulinDoseWarningNotification(warningResult);
      expect(notification).toBeTruthy();
      expect(notification).toContain('exceeds the safe upper limit');
    });

    it('should return warning message when dose is too low', () => {
      const warningResult = checkInsulinDoseWarning(0.2);
      const notification = triggerInsulinDoseWarningNotification(warningResult);
      expect(notification).toBeTruthy();
      expect(notification).toContain('below the effective lower limit');
    });
  });

  describe('Safety-critical edge cases', () => {
    it('should detect boundary violations at upper limit + 0.1', () => {
      const result = checkInsulinDoseWarning(DEFAULT_DOSE_LIMITS.upperLimit + 0.1);
      expect(result.hasWarning).toBe(true);
      expect(result.warningType).toBe('DOSE_TOO_HIGH');
    });

    it('should detect boundary violations at lower limit - 0.1', () => {
      const result = checkInsulinDoseWarning(DEFAULT_DOSE_LIMITS.lowerLimit - 0.1);
      expect(result.hasWarning).toBe(true);
      expect(result.warningType).toBe('DOSE_TOO_LOW');
    });

    it('should handle floating point precision correctly', () => {
      const result = checkInsulinDoseWarning(10.123456789);
      expect(result.dose).toBe(10.123456789);
      expect(result.hasWarning).toBe(false);
    });
  });
});
