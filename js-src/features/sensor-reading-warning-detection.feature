Feature: Sensor Reading Warning Detection
  As an insulin delivery system
  I want to detect abnormal sensor readings and issue warnings
  So that users are alerted to potential safety issues

  Background:
    Given the insulin delivery system is initialized
    And the sensor warning system is enabled

  @tests:spec-sensor-reading-warning @id:sensor-warning-normal
  Scenario: Normal sensor reading does not trigger warning
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    When a sensor reading of 120 mg/dL is received
    Then no warning notification should be issued
    And the system status should be "Normal"

  @tests:spec-sensor-reading-warning @id:sensor-warning-high
  Scenario: Sensor reading exceeds upper limit triggers warning
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    When a sensor reading of 220 mg/dL is received
    Then a warning notification should be issued
    And the warning message should contain "Sensor reading exceeds upper limit"
    And the system status should be "Warning"

  @tests:spec-sensor-reading-warning @id:sensor-warning-low
  Scenario: Sensor reading below lower limit triggers warning
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    When a sensor reading of 55 mg/dL is received
    Then a warning notification should be issued
    And the warning message should contain "Sensor reading below lower limit"
    And the system status should be "Warning"

  @tests:spec-sensor-reading-warning @id:sensor-warning-boundary-upper
  Scenario: Sensor reading at upper boundary does not trigger warning
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    When a sensor reading of 180 mg/dL is received
    Then no warning notification should be issued
    And the system status should be "Normal"

  @tests:spec-sensor-reading-warning @id:sensor-warning-boundary-lower
  Scenario: Sensor reading at lower boundary does not trigger warning
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    When a sensor reading of 70 mg/dL is received
    Then no warning notification should be issued
    And the system status should be "Normal"

  @tests:spec-sensor-reading-warning @id:sensor-warning-consecutive
  Scenario: Multiple consecutive abnormal readings maintain warning state
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    And a sensor reading of 220 mg/dL was received
    And a warning notification was issued
    When a sensor reading of 230 mg/dL is received
    Then a warning notification should be issued
    And the warning message should contain "Sensor reading exceeds upper limit"
    And the system status should be "Warning"
    And the warning count should be 2

  @tests:spec-sensor-reading-warning @id:sensor-warning-clearance
  Scenario: Warning clears when reading returns to normal range
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    And a sensor reading of 220 mg/dL was received
    And a warning notification was issued
    And the system status is "Warning"
    When a sensor reading of 120 mg/dL is received
    Then no warning notification should be issued
    And the system status should be "Normal"
    And the warning should be cleared

  @tests:spec-sensor-reading-warning @id:sensor-warning-outdated
  Scenario: Outdated sensor reading triggers warning
    Given the maximum allowable time interval is 15 minutes
    And the last sensor reading was received 20 minutes ago
    When the system checks for outdated readings
    Then a warning notification should be issued
    And the warning message should contain "Sensor reading is outdated"
    And the system status should be "Warning"

  @tests:spec-sensor-reading-warning @id:sensor-warning-timely
  Scenario: Timely sensor reading does not trigger outdated warning
    Given the maximum allowable time interval is 15 minutes
    And the last sensor reading was received 10 minutes ago
    When the system checks for outdated readings
    Then no warning notification should be issued
    And the system status should be "Normal"

  @tests:spec-sensor-reading-warning @id:sensor-warning-mixed
  Scenario Outline: Various sensor readings with different warning conditions
    Given the sensor reading upper limit is 180 mg/dL
    And the sensor reading lower limit is 70 mg/dL
    When a sensor reading of <reading> mg/dL is received
    Then the warning status should be <warning_status>
    And the system status should be "<system_status>"

    Examples:
      | reading | warning_status | system_status |
      | 50      | issued         | Warning       |
      | 69      | issued         | Warning       |
      | 70      | not issued     | Normal        |
      | 100     | not issued     | Normal        |
      | 150     | not issued     | Normal        |
      | 180     | not issued     | Normal        |
      | 181     | issued         | Warning       |
      | 250     | issued         | Warning       |
