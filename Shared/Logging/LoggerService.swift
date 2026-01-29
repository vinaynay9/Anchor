import Foundation
import os

public enum LoggerService {
    public enum Category: String {
        case app
        case storage
        case analytics
        case shield
    }
    
    public static let shared = SharedLogger()
    
    public final class SharedLogger {
        public init() {}
        
        public func logInfo(_ message: String, category: String? = nil) {
            log(message, level: .info, category: category)
        }
        
        public func logWarning(_ message: String, category: String? = nil) {
            log(message, level: .default, category: category)
        }
        
        public func logError(_ message: String, error: Error? = nil, category: String? = nil) {
            var fullMessage = message
            if let error = error {
                fullMessage += " | Error: \(error.localizedDescription)"
            }
            log(fullMessage, level: .error, category: category)
        }
        
        private func log(_ message: String, level: OSLogType, category: String?) {
            let subsystem = Bundle.main.bundleIdentifier ?? "com.vinay.Anchor"
            let categoryName = category ?? Category.app.rawValue
            let logger = Logger(subsystem: subsystem, category: categoryName)
            logger.log(level: level, "\(message, privacy: .public)")
        }
    }
}
