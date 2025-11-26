import SwiftUI
import Combine
import Shared

class UnlockRequestsViewModel: ObservableObject {
    @Published var pendingRequests: [UnlockRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private let screenTimeService = ScreenTimeService.shared
    
    func loadPendingRequests() {
        isLoading = true
        
        Task {
            // TODO: Implement API call
            // let dtos: [UnlockRequestDTO] = try await apiClient.request(.getPendingUnlockRequests, responseType: [UnlockRequestDTO].self)
            // let requests = dtos.compactMap { $0.toUnlockRequest() }
            
            await MainActor.run {
                self.pendingRequests = []
                self.isLoading = false
            }
        }
    }
    
    func approveRequest(_ request: UnlockRequest) {
        Task {
            do {
                // TODO: Call API to approve
                // try await apiClient.request(.approveUnlockRequest(id: request.id))
                
                // Deactivate shields
                try screenTimeService.deactivateShields()
                
                await MainActor.run {
                    self.loadPendingRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func denyRequest(_ request: UnlockRequest) {
        Task {
            do {
                // TODO: Call API to deny
                // try await apiClient.request(.denyUnlockRequest(id: request.id))
                
                await MainActor.run {
                    self.loadPendingRequests()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

