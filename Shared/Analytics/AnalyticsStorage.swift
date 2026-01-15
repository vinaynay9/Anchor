import Foundation

public final class AnalyticsStorage {
    public static let shared = AnalyticsStorage()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.vinay.Anchor.analytics.storage")
    private var baseURLOverride: URL?
    private var maxFileBytesOverride: Int64?
    
    private let retentionDays = 14
    private let maxFileBytes: Int64 = 50_000_000
    
    private init() {}
    
    public func append(_ records: [AnalyticsRecord]) {
        guard !records.isEmpty else { return }
        queue.async {
            self.cleanupOldFiles()
            let grouped = Dictionary(grouping: records) { self.dayString(for: $0.payload.timestamp) }
            for (dayString, dayRecords) in grouped {
                guard let fileURL = self.eventsFileURL(for: dayString) else { continue }
                let directory = fileURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                guard let data = self.encodeLines(dayRecords) else { continue }
                let targetURL = self.resolveWritableURL(baseURL: fileURL, additionalBytes: Int64(data.count))
                
                guard let handle = try? FileHandle(forWritingTo: targetURL) else {
                    try? data.write(to: targetURL, options: .atomic)
                    continue
                }
                
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        }
    }
    
    public func loadAllRecords() -> [AnalyticsRecord] {
        guard let directoryURL = analyticsDirectoryURL() else { return [] }
        let fileManager = FileManager.default
        let urls = (try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        let legacyURL = directoryURL.appendingPathComponent("events.jsonl")
        let allURLs = (urls + [legacyURL]).filter { fileManager.fileExists(atPath: $0.path) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        
        var records: [AnalyticsRecord] = []
        for url in allURLs {
            if let data = try? Data(contentsOf: url) {
                records.append(contentsOf: decodeLines(data))
            }
        }
        return records
    }
    
    public func clearAll() {
        guard let directoryURL = analyticsDirectoryURL() else { return }
        try? FileManager.default.removeItem(at: directoryURL)
    }

    func setBaseURLForTesting(_ url: URL?) {
        queue.sync {
            baseURLOverride = url
        }
    }

    func setMaxFileBytesForTesting(_ bytes: Int64?) {
        queue.sync {
            maxFileBytesOverride = bytes
        }
    }
    
    private func encodeLines(_ records: [AnalyticsRecord]) -> Data? {
        var combined = Data()
        for record in records {
            if let data = try? encoder.encode(record) {
                combined.append(data)
                combined.append(0x0A)
            }
        }
        return combined
    }
    
    private func decodeLines(_ data: Data) -> [AnalyticsRecord] {
        guard !data.isEmpty else { return [] }
        return data
            .split(separator: 0x0A)
            .compactMap { line in
                try? decoder.decode(AnalyticsRecord.self, from: Data(line))
            }
    }
    
    private func analyticsDirectoryURL() -> URL? {
        if let override = baseURLOverride {
            return override.appendingPathComponent("analytics", isDirectory: true)
        }
        guard let containerURL = AppGroupStorage.shared.appGroupContainerURL() else { return nil }
        return containerURL.appendingPathComponent("analytics", isDirectory: true)
    }
    
    private func eventsFileURL(for dayString: String) -> URL? {
        guard let directoryURL = analyticsDirectoryURL() else { return nil }
        return directoryURL.appendingPathComponent("events-\(dayString).jsonl")
    }
    
    private func resolveWritableURL(baseURL: URL, additionalBytes: Int64) -> URL {
        let fileManager = FileManager.default
        let limit = maxFileBytesOverride ?? maxFileBytes
        if let currentSize = fileSize(for: baseURL),
           currentSize + additionalBytes < limit {
            return baseURL
        }
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        let directory = baseURL.deletingLastPathComponent()
        let baseName = baseURL.deletingPathExtension().lastPathComponent
        var index = 2
        while index < 50 {
            let url = directory.appendingPathComponent("\(baseName)-\(index).jsonl")
            if !fileManager.fileExists(atPath: url.path) {
                return url
            }
            if let size = fileSize(for: url), size + additionalBytes < limit {
                return url
            }
            index += 1
        }
        return baseURL
    }
    
    private func fileSize(for url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber else { return nil }
        return size.int64Value
    }
    
    private func cleanupOldFiles() {
        guard let directoryURL = analyticsDirectoryURL() else { return }
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        
        for url in urls {
            let name = url.lastPathComponent
            guard name.hasPrefix("events-"), name.hasSuffix(".jsonl") else { continue }
            let trimmed = name.replacingOccurrences(of: "events-", with: "")
                .replacingOccurrences(of: ".jsonl", with: "")
            let parts = trimmed.split(separator: "-")
            let dateString = parts.prefix(3).joined(separator: "-")
            guard let date = formatter.date(from: String(dateString)) else { continue }
            if date < cutoff {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    private func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
