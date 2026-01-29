Feature: Sensor module

  @tests:spec-sensor-reading-warning @id:sensor-mod-test
  Scenario: Replace-sensor reminder workflow verification
    Given Application is open
    When Data of 8 is entered
    And Form is submitted
    Then Sensor is not read
    And An error message is shown
