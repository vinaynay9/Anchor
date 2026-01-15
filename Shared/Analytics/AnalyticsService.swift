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
        AnalyticsEnvironment.isEnabled ? LocalAnalyticsService() : NoOpAnalyticsService()
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
    private let queue = DispatchQueue(label: "com.vinay.Anchor.analytics.service")
    private var buffer: [AnalyticsRecord] = []
    private let flushThreshold = 25
    private let appOpenDedupWindow: TimeInterval = 5
    
    public init(exportService: AnalyticsExportServiceProtocol = AnalyticsExportServiceProvider.shared) {
        self.exportService = exportService
    }
    
    public func log(event: AnalyticsEvent, payload: AnalyticsPayload) {
        guard AnalyticsEnvironment.isEnabled else { return }
        queue.async {
            if event == .appOpened, self.shouldDedupAppOpen(payload: payload) {
                return
            }
            let dayId = AppGroupStorage.shared.getAnalyticsDayId(for: payload.timestamp)
            let record = AnalyticsRecord(event: event, payload: payload, dayId: dayId)
            self.buffer.append(record)
            if self.buffer.count >= self.flushThreshold {
                self.flushLocked()
            }
        }
    }
    
    public func flush() {
        queue.async {
            self.flushLocked()
            if AnalyticsExportSettings.isEnabled {
                Task {
                    await self.exportService.flush()
                }
            }
        }
    }
    
    private func flushLocked() {
        guard !buffer.isEmpty else { return }
        let records = buffer
        storage.append(records)
        if AnalyticsExportSettings.isEnabled {
            exportService.enqueueForExport(records: records)
        }
        buffer.removeAll(keepingCapacity: true)
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
