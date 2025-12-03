//
//  KeychainService.swift
//  InsulinDeliveryApp
//
//  Secure storage for sensitive data
//  IEC 62304 §5.6 - Security implementation
//

import Foundation
import Security

/// Manages secure storage of sensitive data in iOS Keychain
/// @safety_critical: Protects patient authentication credentials
class KeychainService {
    
    static let shared = KeychainService()
    
    private let service = "com.insulindelivery.patientapp"
    
    private init() {}
    
    func saveToken(_ token: String) {
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "sessionToken",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            AppLogger.shared.log("Session token saved to keychain", level: .info, category: .security)
        } else {
            AppLogger.shared.log("Failed to save token to keychain: \(status)", 
                               level: .error, category: .security)
        }
    }
    
    func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "sessionToken",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }
        
        return nil
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "sessionToken"
        ]
        
        SecItemDelete(query as CFDictionary)
        AppLogger.shared.log("Session token deleted from keychain", level: .info, category: .security)
    }
}