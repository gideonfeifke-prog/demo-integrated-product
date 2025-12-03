//
//  AuthenticationService.swift
//  InsulinDeliveryApp
//
//  Secure authentication and session management service
//  IEC 62304 §5.6 - Software integration and verification
//

import Foundation
import CryptoKit

/// Manages user authentication and secure session handling
/// @safety_critical: Unauthorized access could lead to improper insulin delivery
class AuthenticationService {
    
    static let shared = AuthenticationService()
    
    private let keychainService = KeychainService.shared
    private var sessionToken: String?
    private var sessionExpiry: Date?
    private var failedLoginAttempts: Int = 0
    private var lockoutExpiry: Date?
    
    private init() {}
    
    // MARK: - Authentication
    
    /// Authenticates user with username and password
    /// @safety_requirement: REQ-IDS-105 - Secure authentication
    func login(username: String, password: String, completion: @escaping (Result<UserProfile, AuthError>) -> Void) {
        
        // Check if account is locked out
        if let lockout = lockoutExpiry, lockout > Date() {
            let remaining = Int(lockout.timeIntervalSince(Date()))
            AppLogger.shared.log("Login attempted on locked account: \(username)", 
                               level: .warning, category: .security)
            completion(.failure(.accountLocked(remainingSeconds: remaining)))
            return
        }
        
        // Validate input
        guard !username.isEmpty, !password.isEmpty else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Hash password for transmission
        let passwordHash = hashPassword(password)
        
        // Authenticate with backend
        APIClient.shared.authenticate(username: username, passwordHash: passwordHash) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                // Reset failed attempts on successful login
                self.failedLoginAttempts = 0
                self.lockoutExpiry = nil
                
                // Store session token securely
                self.sessionToken = response.sessionToken
                self.sessionExpiry = Date().addingTimeInterval(SafetyLimits.sessionTimeout)
                
                // Store token in keychain
                self.keychainService.saveToken(response.sessionToken)
                
                AppLogger.shared.log("User logged in successfully: \(username)", 
                                   level: .info, category: .security)
                
                // Fetch user profile
                self.fetchUserProfile { profileResult in
                    switch profileResult {
                    case .success(let profile):
                        completion(.success(profile))
                    case .failure(let error):
                        completion(.failure(.profileLoadFailed(error)))
                    }
                }
                
            case .failure(let error):
                // Increment failed login attempts
                self.failedLoginAttempts += 1
                
                AppLogger.shared.log("Failed login attempt \(self.failedLoginAttempts) for user: \(username)",
                                   level: .warning, category: .security)
                
                // Lock account after max attempts
                if self.failedLoginAttempts >= SafetyLimits.maxFailedLoginAttempts {
                    self.lockoutExpiry = Date().addingTimeInterval(SafetyLimits.accountLockoutDuration)
                    AppLogger.shared.log("Account locked due to failed login attempts: \(username)",
                                       level: .error, category: .security)
                    completion(.failure(.accountLocked(remainingSeconds: Int(SafetyLimits.accountLockoutDuration))))
                } else {
                    completion(.failure(.authenticationFailed(error)))
                }
            }
        }
    }
    
    /// Logs out current user and clears session
    func logout() {
        AppLogger.shared.log("User logged out", level: .info, category: .security)
        
        sessionToken = nil
        sessionExpiry = nil
        keychainService.deleteToken()
        
        // Notify backend of logout
        if let token = sessionToken {
            APIClient.shared.invalidateSession(token: token) { _ in }
        }
    }
    
    /// Verifies if current session is valid
    /// @safety_requirement: REQ-IDS-106 - Session validation
    func isSessionValid() -> Bool {
        guard let expiry = sessionExpiry, let token = sessionToken else {
            return false
        }
        
        if Date() > expiry {
            AppLogger.shared.log("Session expired", level: .warning, category: .security)
            logout()
            return false
        }
        
        return !token.isEmpty
    }
    
    /// Refreshes current session token
    func refreshSession(completion: @escaping (Result<Void, AuthError>) -> Void) {
        guard let token = sessionToken else {
            completion(.failure(.noActiveSession))
            return
        }
        
        APIClient.shared.refreshSession(token: token) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let newToken):
                self.sessionToken = newToken
                self.sessionExpiry = Date().addingTimeInterval(SafetyLimits.sessionTimeout)
                self.keychainService.saveToken(newToken)
                completion(.success(()))
                
            case .failure(let error):
                AppLogger.shared.log("Session refresh failed: \(error.localizedDescription)",
                                   level: .error, category: .security)
                self.logout()
                completion(.failure(.sessionRefreshFailed(error)))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func fetchUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        APIClient.shared.fetchUserProfile { result in
            completion(result)
        }
    }
    
    /// Returns current session token for API requests
    func getSessionToken() -> String? {
        return isSessionValid() ? sessionToken : nil
    }
}

// MARK: - Authentication Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case authenticationFailed(Error)
    case accountLocked(remainingSeconds: Int)
    case noActiveSession
    case sessionRefreshFailed(Error)
    case profileLoadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .accountLocked(let remaining):
            return "Account locked. Try again in \(remaining / 60) minutes"
        case .noActiveSession:
            return "No active session. Please log in."
        case .sessionRefreshFailed:
            return "Session refresh failed. Please log in again."
        case .profileLoadFailed(let error):
            return "Failed to load user profile: \(error.localizedDescription)"
        }
    }
}