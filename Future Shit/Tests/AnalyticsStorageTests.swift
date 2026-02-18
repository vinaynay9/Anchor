import XCTest
@testable import Shared

final class AnalyticsStorageTests: XCTestCase {
    private var tempDirectory: URL!
    private let storage = AnalyticsStorage.shared
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnchorAnalyticsTests", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storage.setBaseURLForTesting(tempDirectory)
        storage.setMaxFileBytesForTesting(200)
        storage.clearAll()
    }
    
    override func tearDown() {
        storage.clearAll()
        storage.setBaseURLForTesting(nil)
        storage.setMaxFileBytesForTesting(nil)
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testAppendAndRotationCreatesMultipleFiles() {
        let payload = AnalyticsPayload(
            timestamp: Date(),
            userState: .free,
            metrics: AnalyticsMetrics(stringValues: ["blob": String(repeating: "a", count: 400)])
        )
        let record = AnalyticsRecord(event: .appOpened, payload: payload, dayId: "test-day")
        
        storage.append([record])
        storage.append([record, record])
        let expectation = XCTestExpectation(description: "Wait for append")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        
        let analyticsDir = tempDirectory.appendingPathComponent("analytics", isDirectory: true)
        let urls = (try? FileManager.default.contentsOfDirectory(at: analyticsDir, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(urls.count >= 2)
    }
    
    func testSchemaVersionDefaultsOnDecode() throws {
        let legacy = """
        {"id":"00000000-0000-0000-0000-000000000001","event":"app_opened","payload":{"timestamp":1704067200,"userState":"free","context":null,"metrics":null}}
        """
        let data = Data(legacy.utf8)
        let record = try JSONDecoder().decode(AnalyticsRecord.self, from: data)
        XCTAssertEqual(record.schemaVersion, AnalyticsRecord.schemaVersion)
        XCTAssertFalse(record.dayId.isEmpty)
    }
}
