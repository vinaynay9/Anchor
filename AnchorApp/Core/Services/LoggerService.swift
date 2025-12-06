import Foundation
import os.log

/// Centralized logging service for Anchor app and shield extension.
/// Provides structured logging with OSLog where available, with fallback to print() for debug builds.
///
/// **Categories:**
/// - ScreenTime: Screen Time API operations
/// - DeviceActivity: DeviceActivityMonitor events
/// - Shield: Shield extension decisions
/// - Network: API calls and network operations
/// - AppGroup: AppGroup storage read/write
/// - Session: Session lifecycle events
/// - Proofs: Proof upload/retrieval operations
///
/// **Privacy:**
/// - Never logs user photos, contacts, names, phone numbers, or sensitive content
/// - Only logs structured metadata (IDs, timestamps, operation types)
final class LoggerService {
    static let shared = LoggerService()
    
    private let subsystem = "com.vinay.Anchor"
    private let category = "Diagnostics"
    
    /// Maximum number of log entries to keep in memory (rolling buffer)
    private let maxLogEntries = 500
    
    /// In-memory log buffer for DebugDiagnosticsView
    private var logBuffer: [LogEntry] = []
    private let logBufferQueue = DispatchQueue(label: "com.vinay.Anchor.logBuffer", attributes: .concurrent)
    
    /// Verbose logging flag (can be toggled in DebugDiagnosticsView)
    private(set) var isVerboseLoggingEnabled: Bool
    
    /// Publisher for verbose logging state changes
    private let verboseLoggingSubject: CurrentValueSubject<Bool, Never>
    
    var verboseLoggingPublisher: AnyPublisher<Bool, Never> {
        verboseLoggingSubject.eraseToAnyPublisher()
    }
    
    private init() {
        // Initialize verbose logging from UserDefaults
        let savedValue = UserDefaults.standard.bool(forKey: "LoggerService.verboseLoggingEnabled")
        isVerboseLoggingEnabled = savedValue
        verboseLoggingSubject = CurrentValueSubject<Bool, Never>(savedValue)
        
        // Create OSLog instance
        let osLog = OSLog(subsystem: subsystem, category: category)
        logInfo("LoggerService initialized", category: "App")
    }
    
    // MARK: - Public Logging Methods
    
    /// Logs an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category tag (e.g., "ScreenTime", "Network")
    func logInfo(_ message: String, category: String? = nil) {
        log(message, level: .info, category: category ?? "App")
    }
    
    /// Logs a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category tag
    func logWarning(_ message: String, category: String? = nil) {
        log(message, level: .warning, category: category ?? "App")
    }
    
    /// Logs an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category tag
    ///   - error: Optional error to include in the log
    func logError(_ message: String, error: Error? = nil, category: String? = nil) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, category: category ?? "App")
    }
    
    // MARK: - Internal Logging
    
    private enum LogLevel: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }
    
    private func log(_ message: String, level: LogLevel, category: String) {
        // Sanitize message to prevent logging sensitive data
        let sanitizedMessage = sanitizeMessage(message)
        
        // Format timestamp
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestampString = formatter.string(from: timestamp)
        
        // Format log entry
        let formattedMessage = "[\(timestampString)][\(level.rawValue)][\(category)] \(sanitizedMessage)"
        
        // Log to OSLog
        let osLog = OSLog(subsystem: subsystem, category: category)
        let osLogType: OSLogType
        switch level {
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, sanitizedMessage)
        
        // Fallback to print for debug builds
        #if DEBUG
        print(formattedMessage)
        #endif
        
        // Add to in-memory buffer
        addToBuffer(LogEntry(
            timestamp: timestamp,
            level: level.rawValue,
            category: category,
            message: sanitizedMessage
        ))
    }
    
    // MARK: - Log Buffer Management
    
    private struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: String
        let category: String
        let message: String
    }
    
    private func addToBuffer(_ entry: LogEntry) {
        logBufferQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.logBuffer.append(entry)
            
            // Keep only the most recent entries
            if self.logBuffer.count > self.maxLogEntries {
                self.logBuffer.removeFirst(self.logBuffer.count - self.maxLogEntries)
            }
        }
    }
    
    /// Retrieves recent log entries for display in DebugDiagnosticsView
    /// - Parameter limit: Maximum number of entries to return (default: 100)
    /// - Returns: Array of formatted log entries
    func getRecentLogs(limit: Int = 100) -> [String] {
        return logBufferQueue.sync {
            let entries = Array(logBuffer.suffix(limit))
            return entries.map { entry in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                let timeString = formatter.string(from: entry.timestamp)
                return "[\(timeString)][\(entry.level)][\(entry.category)] \(entry.message)"
            }
        }
    }
    
    /// Clears the log buffer
    func clearLogs() {
        logBufferQueue.async(flags: .barrier) { [weak self] in
            self?.logBuffer.removeAll()
        }
    }
    
    /// Toggles verbose logging mode
    func setVerboseLogging(_ enabled: Bool) {
        isVerboseLoggingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "LoggerService.verboseLoggingEnabled")
        verboseLoggingSubject.send(enabled)
        logInfo("Verbose logging \(enabled ? "enabled" : "disabled")", category: "App")
    }
    
    // MARK: - Message Sanitization
    
    /// Sanitizes log messages to prevent logging sensitive data
    /// - Parameter message: The original message
    /// - Returns: Sanitized message with sensitive data redacted
    private func sanitizeMessage(_ message: String) -> String {
        var sanitized = message
        
        // Remove potential phone numbers (basic pattern matching)
        sanitized = sanitized.replacingOccurrences(
            of: #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#,
            with: "[REDACTED_PHONE]",
            options: .regularExpression
        )
        
        // Remove potential email addresses
        sanitized = sanitized.replacingOccurrences(
            of: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#,
            with: "[REDACTED_EMAIL]",
            options: .regularExpression
        )
        
        // Note: We don't log photos, contacts, or names by design
        // This is enforced at the call site, not here
        
        return sanitized
    }
}

// MARK: - Combine Support

import Combine

