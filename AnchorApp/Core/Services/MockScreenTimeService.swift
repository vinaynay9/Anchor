import Foundation
import Shared

// MARK: - Mock Screen Time Service
// This implementation works in simulator and doesn't require real Screen Time entitlements
// Supports simulation mode for testing various scenarios

class MockScreenTimeService: ScreenTimeServiceProtocol {
    static let shared = MockScreenTimeService()
    
    private var isBlocking: Bool = false
    private var authorizationStatus: ScreenTimeAuthorizationStatus = .notDetermined
    private var currentSession: LockSession?
    
    // MARK: - Simulation Mode Configuration
    
    /// When true, enables detailed logging for debugging
    var simulationLoggingEnabled: Bool = true
    
    /// Simulates authorization failure when set to true
    var simulateAuthorizationFailure: Bool = false
    
    /// Simulates specific authorization status for testing
    var simulatedAuthorizationStatus: ScreenTimeAuthorizationStatus? = nil
    
    /// Simulates shield being displayed
    var simulateShieldActive: Bool = false
    
    /// Simulates a fake blocked app bundle ID
    var simulatedBlockedBundleId: String? = nil
    
    /// Simulates DeviceActivity interval events
    var simulatedDeviceActivityEvents: [String] = []
    
    /// Delay in nanoseconds for simulating network/system latency
    var simulatedLatencyNanoseconds: UInt64 = 100_000_000 // 0.1 seconds
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        logSimulation("Requesting Screen Time authorization...")
        
        // Simulate authorization request with configurable delay
        try await Task.sleep(nanoseconds: simulatedLatencyNanoseconds * 5)
        
        // Check if we should simulate failure
        if simulateAuthorizationFailure {
            logSimulation("❌ Authorization failed (simulated)")
            throw ScreenTimeError.authorizationDenied
        }
        
        // Use simulated status if set, otherwise approve
        if let simulated = simulatedAuthorizationStatus {
            authorizationStatus = simulated
            logSimulation("Authorization set to simulated status: \(simulated)")
        } else {
            authorizationStatus = .approved
            logSimulation("✅ Authorization granted")
        }
    }
    
    func getAuthorizationStatus() -> ScreenTimeAuthorizationStatus {
        // Return simulated status if set
        if let simulated = simulatedAuthorizationStatus {
            return simulated
        }
        return authorizationStatus
    }
    
    func isAuthorized() -> Bool {
        return getAuthorizationStatus() == .approved
    }
    
    // MARK: - Logging Helper
    
    private func logSimulation(_ message: String) {
        guard simulationLoggingEnabled else { return }
        print("🔧 [MockScreenTime] \(message)")
    }
    
    // MARK: - Blocking Control
    
    func startBlocking(for session: LockSession) async {
        // Simulate blocking delay
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        
        isBlocking = true
        currentSession = session
        simulateShieldActive = true
        
        logSimulation("🔒 Started blocking for session \(session.id)")
        logSimulation("   - Duration: \(session.endTime?.timeIntervalSince(session.startTime) ?? 0) seconds")
        logSimulation("   - Apps blocked: \(session.appsBlocked.count)")
        
        if let categories = session.selectedCategories {
            logSimulation("   - Categories: \(categories.map { $0.displayName }.joined(separator: ", "))")
        }
        
        // Simulate DeviceActivity event
        simulatedDeviceActivityEvents.append("intervalDidStart:\(session.id.uuidString)")
    }
    
    func updateBlocking(for session: LockSession) async throws {
        // Simulate update delay
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        
        currentSession = session
        
        logSimulation("🔄 Updated blocking for session \(session.id)")
        if let categories = session.selectedCategories {
            logSimulation("   - Categories: \(categories.map { $0.displayName }.joined(separator: ", "))")
        }
    }
    
    func stopBlocking() async {
        // Simulate unblocking delay
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        
        let sessionId = currentSession?.id.uuidString ?? "unknown"
        
        isBlocking = false
        currentSession = nil
        simulateShieldActive = false
        
        logSimulation("🔓 Stopped blocking")
        
        // Simulate DeviceActivity event
        simulatedDeviceActivityEvents.append("intervalDidEnd:\(sessionId)")
    }
    
    func startBlockingForScheduledSession(sessionId: UUID, categories: [AppCategory]?, schedule: LockSessionSchedule) async {
        // Simulate blocking delay
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        
        isBlocking = true
        simulateShieldActive = true
        
        logSimulation("🔒 Started scheduled blocking for session \(sessionId)")
        if let categories = categories {
            logSimulation("   - Categories: \(categories.map { $0.displayName }.joined(separator: ", "))")
        }
        logSimulation("   - Weekdays: \(schedule.weekdays.sorted())")
        
        // Simulate DeviceActivity event
        simulatedDeviceActivityEvents.append("intervalDidStart:\(sessionId.uuidString)")
    }

    func applyDailyAnchor() async {
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        isBlocking = true
        simulateShieldActive = true
        logSimulation("🧷 Applied daily anchor blocking")
    }

    func applyChallengeOverrides() async {
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        logSimulation("🎯 Applied challenge overrides (simulated)")
    }

    func emergencyUnanchor(duration: TimeInterval) async {
        try? await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        isBlocking = false
        simulateShieldActive = false
        logSimulation("🚨 Emergency unanchor for \(duration) seconds")
    }
    
    // MARK: - Mock State Accessors (for testing)
    
    var isCurrentlyBlocking: Bool {
        return isBlocking
    }
    
    var activeSession: LockSession? {
        return currentSession
    }
    
    var isShieldActive: Bool {
        return simulateShieldActive
    }
    
    var blockedBundleId: String? {
        return simulatedBlockedBundleId
    }
    
    var deviceActivityEvents: [String] {
        return simulatedDeviceActivityEvents
    }
    
    // MARK: - Simulation Control Methods
    
    /// Resets all mock state to initial values
    func reset() {
        isBlocking = false
        currentSession = nil
        authorizationStatus = .notDetermined
        simulateAuthorizationFailure = false
        simulatedAuthorizationStatus = nil
        simulateShieldActive = false
        simulatedBlockedBundleId = nil
        simulatedDeviceActivityEvents = []
        
        logSimulation("🔄 Mock state reset")
    }
    
    /// Simulates a user attempting to open a blocked app
    /// - Parameter bundleId: The bundle identifier of the blocked app
    func simulateBlockedAppLaunch(bundleId: String) {
        guard isBlocking else {
            logSimulation("⚠️ Cannot simulate blocked app launch - not currently blocking")
            return
        }
        
        simulatedBlockedBundleId = bundleId
        simulateShieldActive = true
        
        logSimulation("🛡️ Simulated blocked app launch: \(bundleId)")
        logSimulation("   - Shield is now active")
    }
    
    /// Simulates shield dismissal (e.g., after unlock approval)
    func simulateShieldDismiss() {
        simulateShieldActive = false
        simulatedBlockedBundleId = nil
        
        logSimulation("✨ Simulated shield dismissal")
    }
    
    /// Simulates a DeviceActivity interval start event
    /// - Parameter sessionId: The session UUID
    func simulateIntervalDidStart(sessionId: UUID) {
        simulatedDeviceActivityEvents.append("intervalDidStart:\(sessionId.uuidString)")
        logSimulation("📍 Simulated intervalDidStart for session: \(sessionId.uuidString)")
    }
    
    /// Simulates a DeviceActivity interval end event
    /// - Parameter sessionId: The session UUID
    func simulateIntervalDidEnd(sessionId: UUID) {
        simulatedDeviceActivityEvents.append("intervalDidEnd:\(sessionId.uuidString)")
        logSimulation("📍 Simulated intervalDidEnd for session: \(sessionId.uuidString)")
    }
    
    /// Clears all simulated DeviceActivity events
    func clearDeviceActivityEvents() {
        simulatedDeviceActivityEvents = []
        logSimulation("🗑️ Cleared DeviceActivity events")
    }
    
    /// Creates a fake session for testing purposes
    /// - Parameters:
    ///   - durationMinutes: Session duration in minutes
    ///   - categories: Optional app categories to block
    /// - Returns: A fake LockSession for testing
    static func createFakeSession(
        durationMinutes: Int = 25,
        categories: [AppCategory]? = nil
    ) -> LockSession {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(Double(durationMinutes) * 60)
        
        return LockSession(
            id: UUID(),
            userId: UUID(),
            status: .active,
            startTime: startTime,
            endTime: endTime,
            appsBlocked: ["com.apple.mobilesafari", "com.instagram.Instagram"],
            accountabilityPartnerId: UUID(),
            createdAt: startTime,
            selectedCategories: categories,
            schedule: nil,
            events: []
        )
    }
}
