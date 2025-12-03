/**
 * When either of the following conditions is met, the system shall issue a warning notification to the user through an appropriate user interface:
 * a) The sensor reading exceeds the predefined upper or lower limits.
 * b) The latest entered sensor reading is outdated according to the defined maximum allowable time interval.

 * @itemId:spec-sensor-reading-warning
 * @itemTitle:"Sensor Reading Warning (Javascript)"
 * @itemFulfills:CS-1,KD-13
 * @itemHasParent:spec-sensor-module
 */

import { checkGlucoseReadingWarning, triggerGlucoseReadingWarningNotification, GlucoseReading } from './glucoseReadingWarning';
import { checkInsulinDoseWarning, triggerInsulinDoseWarningNotification } from './insulinDoseWarning';

export function createReadingWarning() {
  // This function now integrates with the comprehensive warning system
  // implemented in glucoseReadingWarning.ts and insulinDoseWarning.ts
}

/**
 * Legacy compatibility function for sensor reading warnings
 * Delegates to the new glucose reading warning system
 */
export function checkSensorReadingWarning(
  reading: GlucoseReading | null | undefined,
  maxAgeMinutes?: number
) {
  return checkGlucoseReadingWarning(reading, maxAgeMinutes);
}

export function triggerSensorWarningNotification(warningResult: any) {
  return triggerGlucoseReadingWarningNotification(warningResult);
}
