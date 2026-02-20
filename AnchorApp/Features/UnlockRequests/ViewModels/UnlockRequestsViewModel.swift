import SwiftUI
import Combine
import Shared

@MainActor
class UnlockRequestsViewModel: ObservableObject {
    @Published var pendingRequests: [UnlockRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let unlockRequestService: UnlockRequestServiceProtocol
    private var notificationObserver: NSObjectProtocol?
    
    init(unlockRequestService: UnlockRequestServiceProtocol = UnlockRequestService.shared) {
        self.unlockRequestService = unlockRequestService
        setupNotificationObserver()
    }
    
    // Note: Notification observer cleanup is handled on lifecycle resets.
    
    func loadPendingRequests() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let requests = try await unlockRequestService.getPendingUnlockRequests()
                self.pendingRequests = requests
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func approveRequest(_ request: UnlockRequest) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // Use new method that accepts UnlockRequest and writes bundle ID to AppGroupStorage
                _ = try await unlockRequestService.approveUnlockRequest(request)
                // Reload requests to reflect updated state from backend
                self.loadPendingRequests()
                // Callback for UI feedback (notification already sent by service)
                self.onUnlockRequestApproved(requestId: request.id.uuidString)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func denyRequest(_ request: UnlockRequest) {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // Use new method that accepts UnlockRequest
                _ = try await unlockRequestService.denyUnlockRequest(request)
                // Reload requests to reflect updated state from backend
                self.loadPendingRequests()
                // Callback for UI feedback (notification already sent by service)
                self.onUnlockRequestDenied(requestId: request.id.uuidString)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Notification Callbacks (UI-only wiring)
    
    /// Callback for when unlock request is approved - can be called from UI or notification handlers
    func onUnlockRequestApproved(requestId: String) {
        // Refresh pending requests list
        loadPendingRequests()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    /// Callback for when unlock request is denied - can be called from UI or notification handlers
    func onUnlockRequestDenied(requestId: String) {
        // Refresh pending requests list
        loadPendingRequests()
        
        // Show UI feedback (toast will be shown by NotificationService if notifications disabled)
        // This is a UI-only callback for additional UI updates if needed
    }
    
    // MARK: - Notification Observer
    
    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .unlockRequestStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Reload requests when status changes to reflect real backend state
            Task { @MainActor in
                self?.loadPendingRequests()
            }
        }
    }
    
    private func removeNotificationObserver() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }
}
