import SwiftUI
import Combine
import Shared

class UnlockRequestsViewModel: ObservableObject {
    @Published var pendingRequests: [UnlockRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let unlockRequestService: UnlockRequestServiceProtocol
    
    init(unlockRequestService: UnlockRequestServiceProtocol = UnlockRequestService.shared) {
        self.unlockRequestService = unlockRequestService
    }
    
    func loadPendingRequests() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let requests = try await unlockRequestService.getPendingUnlockRequests()
                await MainActor.run {
                    self.pendingRequests = requests
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func approveRequest(_ request: UnlockRequest) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await unlockRequestService.approveUnlockRequest(requestId: request.id.uuidString)
                
                await MainActor.run {
                    self.loadPendingRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func denyRequest(_ request: UnlockRequest) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await unlockRequestService.denyUnlockRequest(requestId: request.id.uuidString)
                
                await MainActor.run {
                    self.loadPendingRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

