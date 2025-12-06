import SwiftUI
import Shared

struct UnlockRequestDetailView: View {
    let initialRequest: UnlockRequest?
    let sessionId: UUID?
    
    @StateObject private var viewModel = UnlockRequestsViewModel()
    @State private var currentRequest: UnlockRequest?
    @State private var proof: Proof?
    @State private var isLoadingProof = false
    @State private var proofError: String?
    @State private var actionSuccessMessage: String?
    @State private var cardScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 1.0
    
    private let proofService: ProofServiceProtocol
    
    init(request: UnlockRequest? = nil, sessionId: UUID? = nil, proofService: ProofServiceProtocol = ProofService.shared) {
        self.initialRequest = request
        self.sessionId = sessionId
        self.proofService = proofService
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.padding) {
                    if let request = currentRequest ?? initialRequest {
                        VStack(alignment: .leading, spacing: Theme.padding) {
                            Text("Unlock Request")
                                .font(AppTypography.title)
                                .foregroundColor(AppColors.textPrimary)
                                .transition(.opacity)
                        
                        // Status indicator
                        HStack(spacing: Theme.spacing) {
                            Circle()
                                .fill(statusColor(for: request.status))
                                .frame(width: 8, height: 8)
                            Text("Status:")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            Text(request.status.rawValue.capitalized)
                                .font(AppTypography.captionBold)
                                .foregroundColor(statusColor(for: request.status))
                        }
                        .padding(.vertical, Theme.spacing)
                        .padding(.horizontal, Theme.padding)
                        .background(
                            RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                                .fill(statusColor(for: request.status).opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                                .stroke(statusColor(for: request.status).opacity(0.3), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    
                    if let message = request.message {
                        Text(message)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppLayout.chipCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                                    .stroke(AppColors.anchorLavender.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Proof display
                    if isLoadingProof {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.anchorAccent))
                            Text("Loading proof...")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cardCornerRadius)
                    } else if let proof = proof {
                        VStack(alignment: .leading, spacing: Theme.spacing) {
                            Text("Proof Photo")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            AsyncImage(url: proof.thumbnailUrl ?? proof.fileUrl) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                                            .fill(AppColors.secondaryBackground)
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.anchorAccent))
                                    }
                                    .frame(height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .cornerRadius(AppLayout.cardCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            AppColors.anchorAccent.opacity(0.4),
                                                            AppColors.anchorLavender.opacity(0.3)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                        )
                                        .shadow(color: AppColors.anchorAccent.opacity(0.2), radius: 12, x: 0, y: 4)
                                case .failure:
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 32))
                                            .foregroundColor(AppColors.error.opacity(0.7))
                                        Text("Failed to load image")
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(AppColors.secondaryBackground)
                                    .cornerRadius(AppLayout.cardCornerRadius)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                                .stroke(AppColors.anchorLavender.opacity(0.1), lineWidth: 1)
                        )
                    } else if let proofError = proofError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppColors.error)
                            Text("Error loading proof: \(proofError)")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppLayout.chipCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.chipCornerRadius)
                                .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Success message
                    if let successMessage = actionSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text(successMessage)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.success)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(AppLayout.chipCornerRadius)
                    }
                    
                    // Error message from view model
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage) {
                            viewModel.errorMessage = nil
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Action buttons (only show if pending)
                    if request.status == .pending && !viewModel.isLoading {
                        HStack(spacing: Theme.spacing) {
                            Button(action: {
                                HapticFeedback.soft()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    handleDenyRequest(request)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Deny")
                                        .font(AppTypography.bodyBold)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(viewModel.isLoading)
                            
                            Button(action: {
                                HapticFeedback.soft()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    handleApproveRequest(request)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Approve")
                                        .font(AppTypography.bodyBold)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(viewModel.isLoading)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else if viewModel.isLoading {
                        // Show loading state while action is in progress
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.anchorAccent))
                            Text("Processing...")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                        }
                        .padding()
                        .transition(.opacity)
                    } else {
                        // Show resolved status
                        Text("This request has been \(request.status.rawValue).")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppLayout.chipCornerRadius)
                        }
                        .scaleEffect(cardScale)
                        .opacity(cardOpacity)
                    } else {
                    // Creating new unlock request
                    Text("Request Unlock")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    TextField("Message (optional)", text: .constant(""))
                        .textFieldStyle(AppTextFieldStyle())
                    
                    NavigationLink(destination: CaptureProofView(sessionId: sessionId)) {
                        Text("Add Photo Proof")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: {
                        viewModel.sendRequest()
                    }) {
                        Text("Send Request")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.padding)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay(message: "Processing request...")
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentRequest?.status)
        .onAppear {
            currentRequest = initialRequest
            if let request = currentRequest ?? initialRequest {
                loadProof(for: request)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .unlockRequestStatusChanged)) { notification in
            if let userInfo = notification.userInfo,
               let requestId = userInfo["requestId"] as? String,
               let initialRequest = initialRequest,
               requestId == initialRequest.id.uuidString {
                // Request status changed, refresh
                Task {
                    await refreshRequestStatus()
                }
            }
        }
        .onChange(of: viewModel.pendingRequests) { requests in
            // Update current request if it's been removed from pending (approved/denied)
            if let initialRequest = initialRequest,
               !requests.contains(where: { $0.id == initialRequest.id }) {
                // Request was resolved, fetch updated status
                Task {
                    await refreshRequestStatus()
                }
            } else if let initialRequest = initialRequest,
                      let updatedRequest = requests.first(where: { $0.id == initialRequest.id }) {
                // Request still pending but may have been updated
                currentRequest = updatedRequest
            }
        }
    }
    
    // Notification handling is done via onReceive modifier in the view body
    
    @MainActor
    private func refreshRequestStatus() async {
        guard let initialRequest = initialRequest else { return }
        
        do {
            // Reload pending requests to get updated status
            viewModel.loadPendingRequests()
            
            // Wait a moment for the request to complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if request is still in pending list
            if let updatedRequest = viewModel.pendingRequests.first(where: { $0.id == initialRequest.id }) {
                currentRequest = updatedRequest
            } else {
                // Request was resolved, try to get the resolved status
                // For now, we'll mark it as resolved based on the action
                // In a full implementation, you might fetch the specific request
                if actionSuccessMessage?.lowercased().contains("approved") == true {
                    currentRequest = UnlockRequest(
                        id: initialRequest.id,
                        sessionId: initialRequest.sessionId,
                        requesterId: initialRequest.requesterId,
                        partnerId: initialRequest.partnerId,
                        status: .approved,
                        message: initialRequest.message,
                        appBundleId: initialRequest.appBundleId,
                        createdAt: initialRequest.createdAt,
                        resolvedAt: Date()
                    )
                } else if actionSuccessMessage?.lowercased().contains("denied") == true {
                    currentRequest = UnlockRequest(
                        id: initialRequest.id,
                        sessionId: initialRequest.sessionId,
                        requesterId: initialRequest.requesterId,
                        partnerId: initialRequest.partnerId,
                        status: .denied,
                        message: initialRequest.message,
                        appBundleId: initialRequest.appBundleId,
                        createdAt: initialRequest.createdAt,
                        resolvedAt: Date()
                    )
                }
            }
        } catch {
            // Error refreshing, but don't show error to user
            // The view model error will be shown if needed
        }
    }
    
    private func handleApproveRequest(_ request: UnlockRequest) {
        actionSuccessMessage = nil
        
        // Subtle scale + opacity animation on approve
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cardScale = 1.02
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1.0
            }
        }
        
        viewModel.approveRequest(request)
        
        // Set success message after a delay to allow the action to complete
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                if viewModel.errorMessage == nil {
                    actionSuccessMessage = "Request approved successfully"
                }
            }
        }
    }
    
    private func handleDenyRequest(_ request: UnlockRequest) {
        actionSuccessMessage = nil
        
        // Subtle scale + opacity animation on deny
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cardScale = 0.98
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1.0
            }
        }
        
        viewModel.denyRequest(request)
        
        // Set success message after a delay to allow the action to complete
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                if viewModel.errorMessage == nil {
                    actionSuccessMessage = "Request denied"
                }
            }
        }
    }
    
    private func statusColor(for status: UnlockRequestStatus) -> Color {
        switch status {
        case .pending:
            return AppColors.warning
        case .approved:
            return AppColors.success
        case .denied:
            return AppColors.error
        }
    }
    
    private func loadProof(for request: UnlockRequest) {
        isLoadingProof = true
        proofError = nil
        
        Task {
            do {
                // Fetch all proofs for the session and filter by unlock request ID
                let sessionProofs = try await proofService.fetchProofs(for: request.sessionId.uuidString)
                let requestProof = sessionProofs.first { $0.unlockRequestId == request.id }
                
                await MainActor.run {
                    self.proof = requestProof
                    self.isLoadingProof = false
                    if requestProof == nil {
                        // No proof found is not an error, just no proof available
                        self.proofError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.proofError = error.localizedDescription
                    self.isLoadingProof = false
                }
            }
        }
    }
}

