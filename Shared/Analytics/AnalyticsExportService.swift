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
    private let buffer = ExportBuffer()
    
    public init() {}
    
    public func enqueueForExport(records: [AnalyticsRecord]) {
        Task {
            await buffer.append(records)
        }
    }
    
    public func flush() async {
        await buffer.clear()
    }
}

private actor ExportBuffer {
    private var records: [AnalyticsRecord] = []
    
    func append(_ newRecords: [AnalyticsRecord]) {
        records.append(contentsOf: newRecords)
    }
    
    func clear() {
        records.removeAll(keepingCapacity: true)
    }
}

public struct AnalyticsExportServiceProvider {
    public static let shared: AnalyticsExportServiceProtocol = {
        if AnalyticsEnvironment.isEnabled {
            return StubAnalyticsExportService()
        }
        return NoOpAnalyticsExportService()
    }()
}
