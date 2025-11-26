import SwiftUI
import Shared

struct IncomingRequestsListView: View {
    @StateObject private var viewModel = UnlockRequestsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.pendingRequests) { request in
                    NavigationLink(destination: UnlockRequestDetailView(request: request)) {
                        UnlockRequestRowView(request: request)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Unlock Requests")
            .onAppear {
                viewModel.loadPendingRequests()
            }
        }
    }
}

struct UnlockRequestRowView: View {
    let request: UnlockRequest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Unlock Request")
                    .font(AppTypography.bodyBold)
                    .foregroundColor(AppColors.textPrimary)
                if let message = request.message {
                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                Text(request.createdAt, style: .relative)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if request.status == .pending {
                Text("Pending")
                    .font(AppTypography.captionBold)
                    .foregroundColor(AppColors.warning)
            }
        }
        .padding(.vertical, Theme.spacing)
        .listRowBackground(AppColors.secondaryBackground)
    }
}

