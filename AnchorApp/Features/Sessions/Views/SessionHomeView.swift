import SwiftUI

struct SessionHomeView: View {
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.padding) {
                if let session = viewModel.activeSession {
                    ActiveSessionView(session: session, viewModel: viewModel)
                } else {
                    VStack(spacing: Theme.padding * 2) {
                        Text("No active session")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textSecondary)
                        
                        NavigationLink(destination: SessionSetupView()) {
                            Text("Start New Session")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, Theme.padding)
                    }
                }
            }
            .navigationTitle("Sessions")
            .onAppear {
                viewModel.loadActiveSession()
            }
        }
    }
}

