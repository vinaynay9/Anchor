import XCTest
@testable import Shared

final class AnalyticsDedupTests: XCTestCase {
    private var tempDirectory: URL!
    private let storage = AnalyticsStorage.shared
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnchorAnalyticsDedupTests", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storage.setBaseURLForTesting(tempDirectory)
        storage.clearAll()
        AppGroupStorage.shared.setLastAppOpenAt(nil)
    }
    
    override func tearDown() {
        storage.clearAll()
        storage.setBaseURLForTesting(nil)
        AppGroupStorage.shared.setLastAppOpenAt(nil)
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testAppOpenedDedupWithinWindow() {
        let service = LocalAnalyticsService()
        let now = Date()
        let payload = AnalyticsPayload(timestamp: now, userState: .free)
        
        service.log(event: .appOpened, payload: payload)
        service.log(event: .appOpened, payload: payload)
        service.flush()
        
        let expectation = XCTestExpectation(description: "Wait for flush")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        
        let records = storage.loadAllRecords().filter { $0.event == .appOpened }
        XCTAssertEqual(records.count, 1)
    }
}
