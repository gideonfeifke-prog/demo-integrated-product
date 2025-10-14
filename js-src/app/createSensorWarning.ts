/**
 * When either of the following conditions is met, the system shall issue a warning notification to the user through an appropriate user interface:
 * a) The sensor reading exceeds the predefined upper or lower limits.
 * b) The latest entered sensor reading is outdated according to the defined maximum allowable time interval.
 *
 * @itemId:spec-sensor-reading-warning
 * @itemTitle:"Sensor Reading Warning (Javascript)"
 * @itemFulfills:CS-1,KD-13
 * @itemHasParent:spec-sensor-module
 */
export function createReadingWarning(
  readingValue,
  readingTimestampMs,
  upperLimit,
  lowerLimit,
  maxTimeIntervalMs
) {
  const nowMs = Date.now();
  let warning = false;

  // Condition a) Check if the reading is outside of limits
  if (readingValue > upperLimit || readingValue < lowerLimit) {
    warning = true;
    // In a full implementation, you'd log the reason or call the UI function here.
  }

  // Condition b) Check if the reading is outdated
  const timeDifferenceMs = nowMs - readingTimestampMs;
  if (timeDifferenceMs > maxTimeIntervalMs) {
    warning = true;
    // In a full implementation, you'd log the reason or call the UI function here.
  }

  // This simple implementation returns the warning status.
  // A real-world system would trigger a notification side effect here.
  return warning;
}
