//
//  AppDelegate.swift
//  InsulinDeliveryApp
//
//  Insulin Delivery System - Patient Application
//  IEC 62304 Class C Medical Device Software
//
//  Copyright © 2024 Insulin Delivery System. All rights reserved.
//

import UIKit
import UserNotifications

/// Main application delegate for the Insulin Delivery Patient App
/// Handles app lifecycle, push notifications, and background tasks
/// @safety_class: Class C - Software that could result in death or serious injury
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize logging system (IEC 62304 §5.5.5)
        AppLogger.shared.initialize()
        AppLogger.shared.log("Application launched", level: .info, category: .lifecycle)
        
        // Register for remote notifications
        registerForPushNotifications()
        
        // Initialize security services
        SecurityManager.shared.initialize()
        
        // Initialize data synchronization service
        DataSyncManager.shared.initialize()
        
        // Set up background fetch for glucose monitoring
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }
    
    func application(_ application: UIApplication,
                    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        AppLogger.shared.log("Background fetch triggered", level: .info, category: .dataSync)
        
        DataSyncManager.shared.performBackgroundSync { result in
            switch result {
            case .success:
                completionHandler(.newData)
            case .failure:
                completionHandler(.failed)
            }
        }
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.shared.log("Device registered for push notifications", level: .info, category: .notifications)
        
        // Store device token for backend registration
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.shared.log("Failed to register for push notifications: \(error.localizedDescription)",
                           level: .error, category: .notifications)
    }
    
    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                AppLogger.shared.log("Notification authorization error: \(error.localizedDescription)",
                                   level: .error, category: .notifications)
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        AppLogger.shared.log("Application will terminate", level: .info, category: .lifecycle)
        DataSyncManager.shared.performFinalSync()
    }
}