import XCTest
@testable import Shared
@testable import AnchorApp

final class AnalyticsInsightsServiceTests: XCTestCase {
    private var tempDirectory: URL!
    private let storage = AnalyticsStorage.shared
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnchorAnalyticsInsightsTests", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDirectory)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storage.setBaseURLForTesting(tempDirectory)
        storage.clearAll()
    }
    
    override func tearDown() {
        storage.clearAll()
        storage.setBaseURLForTesting(nil)
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testShieldHitsSummary() {
        let todayPayload = AnalyticsPayload(timestamp: Date(), userState: .anchored)
        let yesterdayPayload = AnalyticsPayload(
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            userState: .anchored
        )
        let today = AnalyticsRecord(event: .shieldHit, payload: todayPayload, dayId: "d1")
        let yesterday = AnalyticsRecord(event: .shieldHit, payload: yesterdayPayload, dayId: "d2")
        storage.append([today, yesterday])
        
        let expectation = XCTestExpectation(description: "Wait for append")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        
        let dashboard = AnalyticsInsightsService.shared.buildDashboard(range: .last7Days)
        XCTAssertEqual(dashboard.summary.shieldHitsToday, 1)
        XCTAssertEqual(dashboard.summary.shieldHitsYesterday, 1)
    }
    
    func testMedianPledgeCompletionLatency() {
        let payload1 = AnalyticsPayload(
            timestamp: Date(),
            userState: .anchored,
            metrics: AnalyticsMetrics(doubleValues: ["completionLatencySeconds": 120])
        )
        let payload2 = AnalyticsPayload(
            timestamp: Date(),
            userState: .anchored,
            metrics: AnalyticsMetrics(doubleValues: ["completionLatencySeconds": 240])
        )
        let r1 = AnalyticsRecord(event: .pledgeCompleted, payload: payload1, dayId: "d1")
        let r2 = AnalyticsRecord(event: .pledgeCompleted, payload: payload2, dayId: "d1")
        storage.append([r1, r2])
        
        let expectation = XCTestExpectation(description: "Wait for append")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
        
        let dashboard = AnalyticsInsightsService.shared.buildDashboard(range: .last7Days)
        XCTAssertEqual(dashboard.discipline.medianCompletionLatencySeconds, 180)
    }
}
