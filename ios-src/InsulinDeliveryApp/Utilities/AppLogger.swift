//
//  AppLogger.swift
//  InsulinDeliveryApp
//
//  Comprehensive logging system for audit trail and debugging
//  IEC 62304 §5.5.5 - Software documentation and logging
//

import Foundation
import os.log

/// Centralized logging system with categories and severity levels
/// @safety_requirement: REQ-IDS-113 - Comprehensive audit logging
class AppLogger {
    
    static let shared = AppLogger()
    
    private let logger: OSLog
    private var logFileURL: URL?
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    enum LogCategory: String {
        case lifecycle = "Lifecycle"
        case authentication = "Authentication"
        case security = "Security"
        case monitoring = "Monitoring"
        case delivery = "Delivery"
        case calculation = "Calculation"
        case dataSync = "DataSync"
        case notifications = "Notifications"
        case ui = "UI"
        case network = "Network"
    }
    
    private init() {
        self.logger = OSLog(subsystem: "com.insulindelivery.patientapp", category: "main")
    }
    
    func initialize() {
        // Set up log file in documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            logFileURL = documentsPath.appendingPathComponent("app_logs.txt")
        }
        
        log("AppLogger initialized", level: .info, category: .lifecycle)
    }
    
    /// Main logging method with categorization and severity
    func log(_ message: String, level: LogLevel, category: LogCategory) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] [\(category.rawValue)] [\(level.rawValue)] \(message)"
        
        // Log to system logger
        os_log("%{public}@", log: logger, type: level.osLogType, logMessage)
        
        // Write to file for audit trail
        writeToFile(logMessage)
        
        // For critical errors, also trigger alert mechanism
        if level == .critical {
            handleCriticalLog(message)
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let fileURL = logFileURL else { return }
        
        let logLine = message + "\n"
        
        if let data = logLine.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func handleCriticalLog(_ message: String) {
        // In a production app, this would trigger immediate notification
        // to support team or monitoring system
        print("⚠️ CRITICAL ERROR: \(message)")
    }
    
    /// Retrieves recent logs for debugging
    func getRecentLogs(lines: Int = 100) -> String? {
        guard let fileURL = logFileURL,
              let content = try? String(contentsOf: fileURL) else {
            return nil
        }
        
        let logLines = content.components(separatedBy: "\n")
        let recentLines = logLines.suffix(lines)
        return recentLines.joined(separator: "\n")
    }
    
    /// Exports logs for support or regulatory purposes
    func exportLogs() -> URL? {
        return logFileURL
    }
}