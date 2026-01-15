import Foundation

public protocol AnalyticsExportServiceProtocol {
    func enqueueForExport(records: [AnalyticsRecord])
    func flush() async
}

public protocol RemoteAnalyticsClientProtocol {
    func send(records: [AnalyticsRecord]) async throws
}

public struct AnalyticsExportSettings {
    public static var isEnabled: Bool {
        AnalyticsEnvironment.isEnabled && UserDefaults.standard.bool(forKey: "analyticsRemoteExportEnabled")
    }
    
    public static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "analyticsRemoteExportEnabled")
    }
}

public final class NoOpAnalyticsExportService: AnalyticsExportServiceProtocol {
    public init() {}
    
    public func enqueueForExport(records: [AnalyticsRecord]) {}
    public func flush() async {}
}

public final class StubAnalyticsExportService: AnalyticsExportServiceProtocol {
    private var buffer: [AnalyticsRecord] = []
    private let queue = DispatchQueue(label: "com.vinay.Anchor.analytics.export")
    
    public init() {}
    
    public func enqueueForExport(records: [AnalyticsRecord]) {
        queue.async {
            self.buffer.append(contentsOf: records)
        }
    }
    
    public func flush() async {
        queue.async {
            self.buffer.removeAll(keepingCapacity: true)
        }
    }
}

public struct AnalyticsExportServiceProvider {
    public static let shared: AnalyticsExportServiceProtocol = {
        AnalyticsEnvironment.isEnabled ? StubAnalyticsExportService() : NoOpAnalyticsExportService()
    }()
}
