import Foundation

public protocol AnalyticsServiceProtocol {
    func log(event: AnalyticsEvent, payload: AnalyticsPayload)
    func flush()
}

public struct AnalyticsEnvironment {
    public static var isEnabled: Bool {
        #if ANALYTICS_ENABLED
        return true
        #elseif DEBUG
        return true
        #else
        return false
        #endif
    }
}

public final class AnalyticsServiceProvider {
    public static let shared: AnalyticsServiceProtocol = {
        if AnalyticsEnvironment.isEnabled {
            return LocalAnalyticsService()
        }
        return NoOpAnalyticsService()
    }()
}

public final class NoOpAnalyticsService: AnalyticsServiceProtocol {
    public init() {}
    
    public func log(event: AnalyticsEvent, payload: AnalyticsPayload) {}
    public func flush() {}
}

public final class LocalAnalyticsService: AnalyticsServiceProtocol {
    private let storage = AnalyticsStorage.shared
    private let exportService: AnalyticsExportServiceProtocol
    private let lock = NSLock()
    private var buffer: [AnalyticsRecord] = []
    private let flushThreshold = 25
    private let appOpenDedupWindow: TimeInterval = 5
    
    public init(exportService: AnalyticsExportServiceProtocol = AnalyticsExportServiceProvider.shared) {
        self.exportService = exportService
    }
    
    public func log(event: AnalyticsEvent, payload: AnalyticsPayload) {
        guard AnalyticsEnvironment.isEnabled else { return }
        if event == .appOpened, shouldDedupAppOpen(payload: payload) {
            return
        }
        let dayId = AppGroupStorage.shared.getAnalyticsDayId(for: payload.timestamp)
        let record = AnalyticsRecord(event: event, payload: payload, dayId: dayId)
        var recordsToFlush: [AnalyticsRecord] = []
        lock.lock()
        buffer.append(record)
        if buffer.count >= flushThreshold {
            recordsToFlush = buffer
            buffer.removeAll(keepingCapacity: true)
        }
        lock.unlock()
        if !recordsToFlush.isEmpty {
            storage.append(recordsToFlush)
            if AnalyticsExportSettings.isEnabled {
                exportService.enqueueForExport(records: recordsToFlush)
            }
        }
    }
    
    public func flush() {
        var recordsToFlush: [AnalyticsRecord] = []
        lock.lock()
        if !buffer.isEmpty {
            recordsToFlush = buffer
            buffer.removeAll(keepingCapacity: true)
        }
        lock.unlock()
        if !recordsToFlush.isEmpty {
            storage.append(recordsToFlush)
            if AnalyticsExportSettings.isEnabled {
                exportService.enqueueForExport(records: recordsToFlush)
            }
        }
        if AnalyticsExportSettings.isEnabled {
            Task {
                await exportService.flush()
            }
        }
    }

    private func shouldDedupAppOpen(payload: AnalyticsPayload) -> Bool {
        let now = payload.timestamp
        if let lastOpen = AppGroupStorage.shared.getLastAppOpenAt(),
           now.timeIntervalSince(lastOpen) < appOpenDedupWindow {
            return true
        }
        AppGroupStorage.shared.setLastAppOpenAt(now)
        return false
    }
}
