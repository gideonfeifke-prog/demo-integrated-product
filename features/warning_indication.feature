Feature: Warning Indication
  As a medical device system
  I need to display warning indications when faults are detected
  So that users can take appropriate action for safe operation

  Background:
    Given the User Warning Indication Module (KD-143) is active
    And the Warning Indication Logic Module (KD-118) is operational
    And the system complies with 21 CFR 820 and IEC 60601-1-8

  Scenario: Display warning indicator when a fault is detected
    Given the device is operating normally
    And a fault condition occurs
    When the system processes the fault
    Then a warning indication should be displayed to the user
    And the warning log should be updated

  Scenario: Visual warning indicator is activated
    Given the device is operating normally
    And a fault condition is detected by the Warning Indication Logic Module
    When the fault severity requires user attention
    Then a visual warning indicator should be displayed on the interface
    And the indicator should remain visible until acknowledged

  Scenario: Audible warning indicator is activated
    Given the device is operating normally
    And a critical fault condition occurs
    When the system evaluates the fault as requiring immediate attention
    Then an audible warning should be emitted
    And the audible warning should continue until user acknowledgment

  Scenario: User acknowledges warning indication
    Given a warning indication is currently displayed
    And the warning requires explicit user acknowledgment
    When the user acknowledges the warning through the interface
    Then the warning indication should be cleared from active display
    And the acknowledgment should be recorded in the audit log
    And the timestamp of acknowledgment should be captured

  Scenario: Warning audit log is maintained
    Given the device monitoring system is active
    When a fault condition triggers a warning indication
    Then the warning event should be logged with timestamp
    And the log entry should include fault type and severity
    And the log entry should include system state at time of fault
    And the log should be accessible for compliance auditing

  Scenario: Multiple concurrent warnings are handled
    Given the device is operating normally
    And multiple fault conditions occur simultaneously
    When the system processes all fault conditions
    Then all warning indications should be displayed according to priority
    And each warning should be individually trackable in the audit log
    And the system should support acknowledgment of each warning separately
