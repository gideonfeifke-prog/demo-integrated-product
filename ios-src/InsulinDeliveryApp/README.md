# iOS Patient Client - Insulin Delivery System

## Overview

This is the iOS patient application for the Insulin Delivery System, a Class C medical device software designed in compliance with IEC 62304 standards and FDA guidance for mobile medical applications.

## Safety Classification

**IEC 62304 Class C** - Software that could result in death or serious injury if it fails.

## Features

### Core Functionality

1. **User Authentication**
   - Secure login with session management
   - Account lockout after failed attempts
   - Token-based authentication with auto-refresh
   - Keychain storage for credentials

2. **Real-time Glucose Monitoring**
   - Continuous glucose monitoring every 5 minutes
   - Trend analysis and predictive alerts
   - Historical data visualization
   - Time-in-range calculations

3. **Insulin Delivery Control**
   - Safe bolus delivery with multiple validation layers
   - Active insulin tracking
   - Daily dose limits
   - Emergency dose cancellation

4. **Bolus Calculator**
   - Carbohydrate-based dosing
   - Correction dose calculation
   - Active insulin consideration
   - Safety warnings and validations

5. **Alert System**
   - Critical glucose alerts (overrides Do Not Disturb)
   - Predictive low glucose warnings
   - Sensor connection monitoring
   - Delivery failure notifications

6. **Offline Mode**
   - Local data storage
   - Automatic background synchronization
   - Conflict resolution

7. **Data Management**
   - 24-hour glucose history storage
   - 90-day insulin delivery history
   - Comprehensive audit logging
   - Secure data transmission

## Architecture

### Project Structure

```
ios-src/InsulinDeliveryApp/
├── Models/
│   ├── GlucoseReading.swift       # Glucose measurement data model
│   ├── InsulinDose.swift          # Insulin delivery data model
│   ├── UserProfile.swift          # Patient therapy settings
│   └── SafetyLimits.swift         # System-wide safety constants
├── Services/
│   ├── AuthenticationService.swift      # User authentication
│   ├── GlucoseMonitoringService.swift   # Glucose monitoring
│   ├── InsulinDeliveryService.swift     # Insulin delivery control
│   ├── BolusCalculator.swift            # Dose calculations
│   └── APIClient.swift                  # Backend communication
├── Utilities/
│   ├── AppLogger.swift            # Audit logging system
│   ├── KeychainService.swift      # Secure credential storage
│   ├── AlertManager.swift         # Critical alert management
│   └── DataSyncManager.swift      # Offline sync manager
├── Tests/
│   ├── SafetyLimitsTests.swift
│   ├── BolusCalculatorTests.swift
│   └── GlucoseReadingTests.swift
└── README.md
```

### Key Components

#### Safety Limits

All safety-critical limits are defined in `SafetyLimits.swift`:
- Glucose thresholds (54-400 mg/dL critical range)
- Insulin dosing limits (0.05-25 units)
- Timing constraints (2 min between boluses)
- Session and security timeouts

#### Authentication

Security features:
- SHA-256 password hashing
- Session token with 15-minute timeout
- Account lockout after 5 failed attempts (30-minute lockout)
- Keychain storage for sensitive data

#### Glucose Monitoring

Monitoring capabilities:
- 5-minute reading intervals
- 10-minute sensor timeout detection
- Trend analysis (7 trend states)
- 24-hour history retention
- Time-in-range calculations

#### Insulin Delivery

Safety validations:
1. Dose parameter validation
2. Minimum time between doses (2 minutes)
3. Daily insulin limit (200 units)
4. Active insulin consideration
5. User confirmation for large doses (≥10 units)

#### Bolus Calculator

Calculation algorithm:
1. **Carb Dose** = Carbohydrates / Insulin-to-Carb Ratio
2. **Correction Dose** = (Current Glucose - Target) / Insulin Sensitivity Factor
3. **Total Dose** = Carb Dose + Correction Dose - Active Insulin
4. Round to nearest 0.05 units
5. Apply personal maximum limits

## Safety Requirements

This implementation addresses the following safety requirements:

- **REQ-IDS-100**: System safety limits enforcement
- **REQ-IDS-101**: Critical glucose level detection
- **REQ-IDS-102**: Insulin dose validation
- **REQ-IDS-103**: Therapy settings validation
- **REQ-IDS-104**: Active insulin consideration
- **REQ-IDS-105**: Secure authentication
- **REQ-IDS-106**: Session validation
- **REQ-IDS-107**: Continuous glucose monitoring
- **REQ-IDS-108**: Glucose alert processing
- **REQ-IDS-109**: Safe insulin delivery with validation
- **REQ-IDS-110**: Emergency dose cancellation
- **REQ-IDS-111**: Active insulin tracking
- **REQ-IDS-112**: Accurate bolus calculation
- **REQ-IDS-113**: Comprehensive audit logging
- **REQ-IDS-114**: Critical alert delivery
- **REQ-IDS-115**: Reliable data persistence

## Regulatory Compliance

### IEC 62304 Compliance

- **§5.5.2** - Safety requirements implementation (SafetyLimits.swift)
- **§5.5.3** - Data item definitions (Models/)
- **§5.5.5** - Software documentation and logging (AppLogger.swift)
- **§5.6** - Software integration and verification (Services/)
- **§5.7** - Software unit testing (Tests/)

### FDA Guidance

This application follows FDA guidance for mobile medical applications:
- Secure authentication and data transmission
- Comprehensive error handling
- Clinical decision support with appropriate warnings
- Fail-safe defaults
- Audit trail for regulatory compliance

## Testing

Unit tests are provided for safety-critical components:

```bash
# Run unit tests
xcodebuild test -scheme InsulinDeliveryApp -destination 'platform=iOS Simulator,name=iPhone 14'
```

Test coverage includes:
- Safety limit validations
- Bolus calculation accuracy
- Glucose reading classifications
- Dose validation logic
- Active insulin calculations

## Configuration

### Backend API

Update the base URL in `APIClient.swift`:
```swift
self.baseURL = URL(string: "https://api.insulindelivery.example.com")!
```

### Safety Parameters

Safety limits are hard-coded in `SafetyLimits.swift` and should only be modified through proper change control procedures with appropriate safety analysis.

## Security Considerations

1. **Data Encryption**: All data transmitted to/from backend uses TLS 1.2+
2. **Credential Storage**: Passwords and tokens stored in iOS Keychain
3. **Session Management**: 15-minute timeout with automatic refresh
4. **Input Validation**: All user inputs validated against safety limits
5. **Audit Logging**: Comprehensive logging for security and debugging

## Known Limitations

1. Requires iOS 14.0 or later
2. Requires continuous internet connectivity for real-time monitoring
3. Background fetch limited to iOS system constraints
4. Glucose readings limited to 5-minute intervals

## Future Enhancements

- Apple Watch companion app
- HealthKit integration
- Siri voice commands for glucose checks
- Carbohydrate database
- Integration with continuous glucose monitors
- Advanced data analytics and insights

## Support

For technical support or to report issues:
- Email: support@insulindelivery.example.com
- Phone: 1-800-INSULIN

## License

Copyright © 2024 Insulin Delivery System. All rights reserved.

This software is a medical device and is subject to regulatory controls.
Unauthorized copying, modification, or distribution is strictly prohibited.

## Version History

### Version 1.0.1 (Current)
- Initial release
- Core insulin delivery functionality
- Real-time glucose monitoring
- Bolus calculator
- Offline mode support
- Comprehensive safety validations
