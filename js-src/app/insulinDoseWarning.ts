/**
 * Insulin Dose Warning Module
 * 
 * The system shall issue a warning notification to the user through an appropriate
 * user interface when the recommended insulin dose exceeds the predefined upper or lower limits.
 * 
 * @itemId:spec-insulin-dose-warning
 * @itemTitle:"Insulin Dose Warning"
 * @itemFulfills:KD-3,KXREC3S1ESH1R3P88YBGTY0E2T186DF
 * @itemHasParent:spec-warning-indication
 * @safetyClass:B
 * @standard:IEC-62304
 */

export interface InsulinDoseLimits {
  upperLimit: number; // Maximum safe insulin dose in units
  lowerLimit: number; // Minimum effective insulin dose in units
}

export interface InsulinDoseWarningResult {
  hasWarning: boolean;
  warningType?: 'DOSE_TOO_HIGH' | 'DOSE_TOO_LOW';
  dose: number;
  limit: number;
  message?: string;
}

/**
 * Default safety limits for insulin dosing
 * These should be configurable per patient profile in production
 */
export const DEFAULT_DOSE_LIMITS: InsulinDoseLimits = {
  upperLimit: 50.0, // units
  lowerLimit: 0.5   // units
};

/**
 * Validates if an insulin dose is within safe limits
 * 
 * @param dose - The recommended insulin dose in units
 * @param limits - The predefined upper and lower dose limits
 * @returns Warning result indicating if dose exceeds limits
 */
export function checkInsulinDoseWarning(
  dose: number,
  limits: InsulinDoseLimits = DEFAULT_DOSE_LIMITS
): InsulinDoseWarningResult {
  // Validate inputs
  if (typeof dose !== 'number' || isNaN(dose) || dose < 0) {
    throw new Error('Invalid insulin dose: must be a non-negative number');
  }

  if (limits.upperLimit <= limits.lowerLimit) {
    throw new Error('Invalid dose limits: upper limit must be greater than lower limit');
  }

  // Check if dose exceeds upper limit
  if (dose > limits.upperLimit) {
    return {
      hasWarning: true,
      warningType: 'DOSE_TOO_HIGH',
      dose,
      limit: limits.upperLimit,
      message: `WARNING: Recommended insulin dose (${dose.toFixed(1)} units) exceeds the safe upper limit (${limits.upperLimit.toFixed(1)} units). Please review the dose calculation and consult healthcare provider.`
    };
  }

  // Check if dose is below lower limit
  if (dose < limits.lowerLimit) {
    return {
      hasWarning: true,
      warningType: 'DOSE_TOO_LOW',
      dose,
      limit: limits.lowerLimit,
      message: `WARNING: Recommended insulin dose (${dose.toFixed(1)} units) is below the effective lower limit (${limits.lowerLimit.toFixed(1)} units). Please review the dose calculation.`
    };
  }

  // Dose is within safe limits
  return {
    hasWarning: false,
    dose,
    limit: 0
  };
}

/**
 * Triggers a warning notification to the user interface
 * 
 * @param warningResult - The warning result from dose validation
 * @returns The warning message to display, or null if no warning
 */
export function triggerInsulinDoseWarningNotification(
  warningResult: InsulinDoseWarningResult
): string | null {
  if (!warningResult.hasWarning) {
    return null;
  }

  // In a real implementation, this would integrate with the UI notification system
  // For now, we return the warning message
  return warningResult.message || 'Insulin dose warning detected';
}
