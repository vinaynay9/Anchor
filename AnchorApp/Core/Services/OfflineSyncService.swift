import Foundation
import Shared
import Combine

/// Service that handles syncing queued offline operations when network is restored
class OfflineSyncService {
    static let shared = OfflineSyncService()
    
    private let networkMonitor = NetworkMonitor.shared
    private let persistenceService = PersistenceService.shared
    private let unlockRequestService: UnlockRequestServiceProtocol
    private let proofService: ProofServiceProtocol
    private let sessionService: SessionServiceProtocol
    
    private var syncTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    /// Retry interval in seconds (default: 30 seconds)
    var retryInterval: TimeInterval = 30.0
    
    init(
        unlockRequestService: UnlockRequestServiceProtocol = UnlockRequestService.shared,
        proofService: ProofServiceProtocol = ProofService.shared,
        sessionService: SessionServiceProtocol = SessionService.shared
    ) {
        self.unlockRequestService = unlockRequestService
        self.proofService = proofService
        self.sessionService = sessionService
        
        setupNetworkObserver()
    }
    
    /// Sets up observer for network connectivity changes
    private func setupNetworkObserver() {
        networkMonitor.$isConnected
            .dropFirst() // Skip initial value
            .sink { [weak self] isConnected in
                if isConnected {
                    print("🌐 [OfflineSyncService] Network restored, starting sync...")
                    self?.syncAll()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Starts periodic sync when app is in foreground
    func startPeriodicSync() {
        stopPeriodicSync()
        
        syncTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            while !Task.isCancelled {
                // Only sync if network is available
                if self.networkMonitor.isConnected {
                    await self.syncAll()
                }
                
                // Wait before next sync attempt
                try? await Task.sleep(nanoseconds: UInt64(self.retryInterval * 1_000_000_000))
            }
        }
    }
    
    /// Stops periodic sync
    func stopPeriodicSync() {
        syncTask?.cancel()
        syncTask = nil
    }
    
    /// Syncs all queued operations
    @MainActor
    func syncAll() async {
        print("🔄 [OfflineSyncService] Starting sync of all queued operations...")
        
        await syncQueuedUnlockRequests()
        await syncPendingProofs()
        
        print("✅ [OfflineSyncService] Sync completed")
    }
    
    /// Syncs queued unlock requests
    @MainActor
    private func syncQueuedUnlockRequests() async {
        let queuedRequests = persistenceService.loadQueuedUnlockRequests()
        
        guard !queuedRequests.isEmpty else {
            return
        }
        
        print("📤 [OfflineSyncService] Syncing \(queuedRequests.count) queued unlock requests...")
        
        for request in queuedRequests {
            do {
                // Try to submit the request again
                // Note: We need to get the active session to resubmit
                if let activeSession = try? await sessionService.getActiveSession(),
                   activeSession.id == request.sessionId {
                    
                    // Create a new request with the same data
                    let newRequest = UnlockRequest(
                        id: UUID(), // New ID for retry
                        sessionId: request.sessionId,
                        requesterId: request.requesterId,
                        partnerId: request.partnerId,
                        status: .pending,
                        message: request.message,
                        appBundleId: request.appBundleId,
                        createdAt: Date(),
                        resolvedAt: nil
                    )
                    
                    // Submit using the service (which will handle API call)
                    _ = try await unlockRequestService.submitUnlockRequest(
                        session: activeSession,
                        appBundleId: request.appBundleId ?? "",
                        reason: request.message
                    )
                    
                    // Remove from queue on success
                    persistenceService.deleteQueuedUnlockRequest(requestId: request.id)
                    print("✅ [OfflineSyncService] Successfully synced unlock request: \(request.id.uuidString)")
                } else {
                    print("⚠️ [OfflineSyncService] Active session not found for request: \(request.id.uuidString)")
                }
            } catch {
                print("❌ [OfflineSyncService] Failed to sync unlock request \(request.id.uuidString): \(error.localizedDescription)")
                // Keep in queue for next retry
            }
        }
    }
    
    /// Syncs pending proof photos
    @MainActor
    private func syncPendingProofs() async {
        let pendingProofs = persistenceService.loadPendingProofs()
        
        guard !pendingProofs.isEmpty else {
            return
        }
        
        print("📸 [OfflineSyncService] Syncing \(pendingProofs.count) pending proof photos...")
        
        for proofMetadata in pendingProofs {
            do {
                guard let imageData = persistenceService.loadPendingProofImage(proofId: proofMetadata.proofId) else {
                    print("⚠️ [OfflineSyncService] Image data not found for proof: \(proofMetadata.proofId.uuidString)")
                    persistenceService.deletePendingProof(proofId: proofMetadata.proofId)
                    continue
                }
                
                // Retry upload
                _ = try await proofService.uploadProof(
                    imageData: imageData,
                    sessionId: proofMetadata.sessionId.uuidString
                )
                
                // Remove from queue on success
                persistenceService.deletePendingProof(proofId: proofMetadata.proofId)
                print("✅ [OfflineSyncService] Successfully synced proof: \(proofMetadata.proofId.uuidString)")
            } catch {
                print("❌ [OfflineSyncService] Failed to sync proof \(proofMetadata.proofId.uuidString): \(error.localizedDescription)")
                // Keep in queue for next retry
            }
        }
    }
}

