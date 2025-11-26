import Foundation
import os.log

enum LogLevel {
    case debug
    case info
    case warning
    case error
}

struct Logger {
    private static let subsystem = "com.anchor.app"
    
    static func log(_ message: String, level: LogLevel = .info, category: String = "App") {
        let osLog = OSLog(subsystem: subsystem, category: category)
        let osLogType: OSLogType
        
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, message)
    }
    
    static func debug(_ message: String, category: String = "App") {
        log(message, level: .debug, category: category)
    }
    
    static func info(_ message: String, category: String = "App") {
        log(message, level: .info, category: category)
    }
    
    static func warning(_ message: String, category: String = "App") {
        log(message, level: .warning, category: category)
    }
    
    static func error(_ message: String, category: String = "App") {
        log(message, level: .error, category: category)
    }
}

