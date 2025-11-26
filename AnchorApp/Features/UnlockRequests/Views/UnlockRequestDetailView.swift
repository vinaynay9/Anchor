import SwiftUI
import Shared

struct UnlockRequestDetailView: View {
    let request: UnlockRequest?
    let sessionId: UUID?
    
    @StateObject private var viewModel = UnlockRequestsViewModel()
    @StateObject private var proofViewModel = ProofViewModel()
    
    init(request: UnlockRequest? = nil, sessionId: UUID? = nil) {
        self.request = request
        self.sessionId = sessionId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.padding) {
                if let request = request {
                    Text("Unlock Request")
                        .font(AppTypography.title)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if let message = request.message {
                        Text(message)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding()
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.accentLight.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // TODO: Show proof if available
                    
                    HStack(spacing: Theme.spacing) {
                        Button(action: {
                            viewModel.denyRequest(request)
                        }) {
                            Text("Deny")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: {
                            viewModel.approveRequest(request)
                        }) {
                            Text("Approve")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
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
                        // TODO: Create unlock request
                    }) {
                        Text("Send Request")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(Theme.padding)
        }
        .background(AppColors.background)
    }
}

