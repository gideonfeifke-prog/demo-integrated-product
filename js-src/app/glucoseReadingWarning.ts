/**
 * Glucose Reading Warning Module
 * 
 * The system shall issue a warning notification to the user through an appropriate
 * user interface when the latest entered glucose reading is outdated according to
 * the defined maximum allowable time interval.
 * 
 * @itemId:spec-glucose-reading-warning
 * @itemTitle:"Glucose Reading Warning"
 * @itemFulfills:KD-3,KXREC3S1ESH1R3P88YBGTY0E2T186DF
 * @itemHasParent:spec-warning-indication
 * @safetyClass:B
 * @standard:IEC-62304
 */

export interface GlucoseReading {
  value: number;        // Glucose value in mg/dL
  timestamp: Date;      // When the reading was taken
  source: 'SENSOR' | 'MANUAL'; // Source of the reading
}

export interface GlucoseReadingWarningResult {
  hasWarning: boolean;
  isOutdated?: boolean;
  reading?: GlucoseReading;
  ageInMinutes?: number;
  maxAgeInMinutes?: number;
  message?: string;
}

/**
 * Default maximum allowable time interval for glucose readings
 * CGM (Continuous Glucose Monitor) readings should be recent for accurate insulin dosing
 */
export const DEFAULT_MAX_READING_AGE_MINUTES = 15; // 15 minutes

/**
 * Checks if a glucose reading is outdated
 * 
 * @param reading - The glucose reading to check
 * @param maxAgeMinutes - Maximum allowable age of the reading in minutes
 * @param currentTime - Current time (defaults to now, can be overridden for testing)
 * @returns Warning result indicating if reading is outdated
 */
export function checkGlucoseReadingWarning(
  reading: GlucoseReading | null | undefined,
  maxAgeMinutes: number = DEFAULT_MAX_READING_AGE_MINUTES,
  currentTime: Date = new Date()
): GlucoseReadingWarningResult {
  // No reading available
  if (!reading) {
    return {
      hasWarning: true,
      isOutdated: true,
      ageInMinutes: Infinity,
      maxAgeInMinutes: maxAgeMinutes,
      message: 'WARNING: No glucose reading available. Please take a glucose reading before calculating insulin dose.'
    };
  }

  // Validate reading
  if (typeof reading.value !== 'number' || isNaN(reading.value) || reading.value < 0) {
    throw new Error('Invalid glucose reading value');
  }

  if (!(reading.timestamp instanceof Date) || isNaN(reading.timestamp.getTime())) {
    throw new Error('Invalid glucose reading timestamp');
  }

  if (maxAgeMinutes <= 0) {
    throw new Error('Invalid max age: must be a positive number');
  }

  // Calculate age of reading in minutes
  const ageInMilliseconds = currentTime.getTime() - reading.timestamp.getTime();
  const ageInMinutes = ageInMilliseconds / (1000 * 60);

  // Check if reading is from the future (clock sync issue)
  if (ageInMinutes < 0) {
    return {
      hasWarning: true,
      isOutdated: false,
      reading,
      ageInMinutes,
      maxAgeInMinutes: maxAgeMinutes,
      message: 'WARNING: Glucose reading timestamp is in the future. Please check system time synchronization.'
    };
  }

  // Check if reading exceeds maximum age
  if (ageInMinutes > maxAgeMinutes) {
    return {
      hasWarning: true,
      isOutdated: true,
      reading,
      ageInMinutes,
      maxAgeInMinutes: maxAgeMinutes,
      message: `WARNING: Glucose reading is outdated (${Math.floor(ageInMinutes)} minutes old). Maximum allowable age is ${maxAgeMinutes} minutes. Please take a new glucose reading before calculating insulin dose.`
    };
  }

  // Reading is current and valid
  return {
    hasWarning: false,
    isOutdated: false,
    reading,
    ageInMinutes,
    maxAgeInMinutes: maxAgeMinutes
  };
}

/**
 * Triggers a warning notification to the user interface
 * 
 * @param warningResult - The warning result from glucose reading validation
 * @returns The warning message to display, or null if no warning
 */
export function triggerGlucoseReadingWarningNotification(
  warningResult: GlucoseReadingWarningResult
): string | null {
  if (!warningResult.hasWarning) {
    return null;
  }

  // In a real implementation, this would integrate with the UI notification system
  // For now, we return the warning message
  return warningResult.message || 'Glucose reading warning detected';
}

/**
 * Combined check for both glucose reading validity and insulin dose safety
 * This should be called before any insulin dose calculation or administration
 * 
 * @param reading - The glucose reading to validate
 * @param dose - The calculated insulin dose to validate
 * @param doseLimits - The safe dose limits
 * @param maxReadingAgeMinutes - Maximum allowable reading age
 * @returns Array of warning messages, empty if no warnings
 */
export function checkAllWarnings(
  reading: GlucoseReading | null | undefined,
  dose: number,
  doseLimits: { upperLimit: number; lowerLimit: number },
  maxReadingAgeMinutes: number = DEFAULT_MAX_READING_AGE_MINUTES
): string[] {
  const warnings: string[] = [];

  // Import the insulin dose warning function
  const { checkInsulinDoseWarning, triggerInsulinDoseWarningNotification } = require('./insulinDoseWarning');

  // Check glucose reading
  const readingWarning = checkGlucoseReadingWarning(reading, maxReadingAgeMinutes);
  const readingMessage = triggerGlucoseReadingWarningNotification(readingWarning);
  if (readingMessage) {
    warnings.push(readingMessage);
  }

  // Check insulin dose
  const doseWarning = checkInsulinDoseWarning(dose, doseLimits);
  const doseMessage = triggerInsulinDoseWarningNotification(doseWarning);
  if (doseMessage) {
    warnings.push(doseMessage);
  }

  return warnings;
}
