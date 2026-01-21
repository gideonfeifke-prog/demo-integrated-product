import { createReadingWarning } from '../app/createSensorWarning';

/**
 * Comprehensive test suite for createReadingWarning function
 * Tests the functionality implemented in PR #8
 * 
 * @itemId:test-sensor-reading-warning
 * @itemTitle:"Test for Sensor Reading Warning"
 * @itemVerifies:spec-sensor-reading-warning
 */
describe('createReadingWarning', () => {
  // Mock Date.now() for consistent timestamp testing
  const MOCK_NOW = 1000000000;
  let originalDateNow: () => number;

  beforeEach(() => {
    originalDateNow = Date.now;
    Date.now = jest.fn(() => MOCK_NOW);
  });

  afterEach(() => {
    Date.now = originalDateNow;
  });

  describe('Limit Exceeded Warning (Condition a)', () => {
    it('should return true when reading exceeds upper limit', () => {
      const result = createReadingWarning(
        105,    // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs (recent)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(true);
    });

    it('should return true when reading is below lower limit', () => {
      const result = createReadingWarning(
        -5,     // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs (recent)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(true);
    });

    it('should return false when reading is within limits', () => {
      const result = createReadingWarning(
        50,     // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs (recent)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should return false when reading equals upper limit', () => {
      const result = createReadingWarning(
        100,    // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs (recent)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should return false when reading equals lower limit', () => {
      const result = createReadingWarning(
        0,      // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs (recent)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });
  });

  describe('Data Stale Warning (Condition b)', () => {
    it('should return true when reading timestamp exceeds max time interval', () => {
      const result = createReadingWarning(
        50,     // readingValue (within limits)
        MOCK_NOW - 6000,  // readingTimestampMs (6 seconds old)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs (5 seconds)
      );
      expect(result).toBe(true);
    });

    it('should return false when reading timestamp is within max time interval', () => {
      const result = createReadingWarning(
        50,     // readingValue (within limits)
        MOCK_NOW - 4000,  // readingTimestampMs (4 seconds old)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs (5 seconds)
      );
      expect(result).toBe(false);
    });

    it('should return false when reading timestamp exactly equals max time interval', () => {
      const result = createReadingWarning(
        50,     // readingValue (within limits)
        MOCK_NOW - 5000,  // readingTimestampMs (exactly 5 seconds old)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs (5 seconds)
      );
      expect(result).toBe(false);
    });

    it('should return true when reading is significantly outdated', () => {
      const result = createReadingWarning(
        50,     // readingValue (within limits)
        MOCK_NOW - 100000,  // readingTimestampMs (100 seconds old)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs (5 seconds)
      );
      expect(result).toBe(true);
    });
  });

  describe('Combined Warning Scenarios', () => {
    it('should return true when both conditions are violated', () => {
      const result = createReadingWarning(
        150,    // readingValue (exceeds upper limit)
        MOCK_NOW - 10000,  // readingTimestampMs (stale)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(true);
    });

    it('should return true when reading is below lower limit and stale', () => {
      const result = createReadingWarning(
        -10,    // readingValue (below lower limit)
        MOCK_NOW - 10000,  // readingTimestampMs (stale)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(true);
    });
  });

  describe('Edge Cases', () => {
    it('should handle negative limits correctly', () => {
      const result = createReadingWarning(
        -50,    // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs
        0,      // upperLimit
        -100,   // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should handle very large reading values', () => {
      const result = createReadingWarning(
        999999, // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs
        1000000, // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should handle zero time interval correctly', () => {
      const result = createReadingWarning(
        50,     // readingValue
        MOCK_NOW - 1,  // readingTimestampMs (1ms old)
        100,    // upperLimit
        0,      // lowerLimit
        0       // maxTimeIntervalMs (zero tolerance)
      );
      expect(result).toBe(true);
    });

    it('should handle current timestamp reading', () => {
      const result = createReadingWarning(
        50,     // readingValue
        MOCK_NOW,  // readingTimestampMs (exactly now)
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should handle decimal reading values', () => {
      const result = createReadingWarning(
        99.9,   // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should handle reading exactly at upper limit boundary', () => {
      const result = createReadingWarning(
        100.0,  // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(false);
    });

    it('should handle reading just above upper limit', () => {
      const result = createReadingWarning(
        100.1,  // readingValue
        MOCK_NOW - 1000,  // readingTimestampMs
        100,    // upperLimit
        0,      // lowerLimit
        5000    // maxTimeIntervalMs
      );
      expect(result).toBe(true);
    });
  });

  describe('Real-world Scenarios', () => {
    it('should trigger warning for temperature sensor exceeding safe range', () => {
      const result = createReadingWarning(
        85,     // readingValue (85°C)
        MOCK_NOW - 2000,  // readingTimestampMs
        80,     // upperLimit (80°C max safe temp)
        -20,    // lowerLimit (-20°C min safe temp)
        10000   // maxTimeIntervalMs (10 seconds)
      );
      expect(result).toBe(true);
    });

    it('should trigger warning for stale humidity sensor reading', () => {
      const result = createReadingWarning(
        45,     // readingValue (45% humidity, normal)
        MOCK_NOW - 61000,  // readingTimestampMs (61 seconds old)
        100,    // upperLimit (100% humidity max)
        0,      // lowerLimit (0% humidity min)
        60000   // maxTimeIntervalMs (60 seconds = 1 minute)
      );
      expect(result).toBe(true);
    });

    it('should not warn for normal pressure sensor reading', () => {
      const result = createReadingWarning(
        1013,   // readingValue (1013 hPa, normal atmospheric pressure)
        MOCK_NOW - 5000,  // readingTimestampMs (5 seconds old)
        1100,   // upperLimit
        900,    // lowerLimit
        30000   // maxTimeIntervalMs (30 seconds)
      );
      expect(result).toBe(false);
    });
  });
});
