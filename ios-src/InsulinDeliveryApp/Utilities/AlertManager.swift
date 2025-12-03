//
//  AlertManager.swift
//  InsulinDeliveryApp
//
//  Critical alert management system
//  IEC 62304 §5.6 - User notifications and alerts
//

import Foundation
import UserNotifications
import AVFoundation

/// Manages critical patient alerts and notifications
/// @safety_critical: Timely alerts are essential for patient safety
class AlertManager {
    
    static let shared = AlertManager()
    
    enum AlertType {
        case criticalLow
        case criticalHigh
        case urgentLow
        case urgentHigh
        case predictiveLow
        case connectionLost
        case deliveryFailed
    }
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    /// Triggers critical alert that overrides Do Not Disturb
    /// @safety_requirement: REQ-IDS-114 - Critical alert delivery
    func triggerCriticalAlert(title: String, message: String, type: AlertType) {
        AppLogger.shared.log("Critical alert triggered: \(title)", level: .critical, category: .notifications)
        
        // Create critical notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .defaultCritical
        content.interruptionLevel = .critical
        
        // Critical alerts should appear immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, 
                                          content: content, 
                                          trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.shared.log("Failed to schedule critical alert: \(error.localizedDescription)",
                                   level: .error, category: .notifications)
            }
        }
        
        // Play alert sound
        playAlertSound(for: type)
    }
    
    /// Triggers standard priority alert
    func triggerAlert(title: String, message: String, type: AlertType) {
        AppLogger.shared.log("Alert triggered: \(title)", level: .warning, category: .notifications)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                          content: content,
                                          trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                AppLogger.shared.log("Failed to schedule alert: \(error.localizedDescription)",
                                   level: .error, category: .notifications)
            }
        }
    }
    
    private func playAlertSound(for type: AlertType) {
        // In production, this would play appropriate alert sounds
        // For critical alerts, sounds should be distinct and attention-getting
        AudioServicesPlaySystemSound(SystemSoundID(1005)) // System alert sound
    }
}