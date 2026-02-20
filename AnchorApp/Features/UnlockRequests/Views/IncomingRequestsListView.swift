import SwiftUI
import Shared

struct IncomingRequestsListView: View {
    @EnvironmentObject var coordinator: MainTabFlow
    @StateObject private var viewModel = UnlockRequestsViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.pendingRequests.isEmpty {
                // Loading state
                LoadingView(message: "Loading requests...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.pendingRequests.isEmpty {
                // Error state
                VStack(spacing: Theme.padding) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.error)
                    Text("Error loading requests")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.textPrimary)
                    Text(errorMessage)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.padding)
                    
                    Button(action: {
                        viewModel.loadPendingRequests()
                    }) {
                        Text("Retry")
                            .font(AppTypography.body)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, Theme.spacing)
                }
                .padding(Theme.padding * 2)
            } else if viewModel.pendingRequests.isEmpty {
                // Empty state
                EmptyStateView(
                    icon: "lock.open",
                    title: "No unlock requests",
                    message: "You don't have any pending unlock requests at the moment",
                    actionTitle: nil,
                    action: nil
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                List {
                    // Error banner if there's an error but we have some requests
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppColors.error)
                            Text(errorMessage)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                            Spacer()
                            Button(action: {
                                viewModel.loadPendingRequests()
                            }) {
                                Text("Retry")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding()
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppLayout.chipCornerRadius)
                        .listRowBackground(AppColors.secondaryBackground)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    ForEach(viewModel.pendingRequests) { request in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                coordinator.navigateToUnlockRequestDetail(request: request)
                            }
                        }) {
                            UnlockRequestRowView(request: request)
                        }
                        .buttonStyle(.plain)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                            Spacer()
                        }
                        .padding()
                        .listRowBackground(AppColors.secondaryBackground)
                    }
                }
                .scrollContentBackground(.hidden)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.pendingRequests.count)
            }
        }
        .navigationTitle("Unlock Requests")
        .refreshable {
            viewModel.loadPendingRequests()
        }
        .onAppear {
            viewModel.loadPendingRequests()
        }
    }
}

struct UnlockRequestRowView: View {
    let request: UnlockRequest
    
    var body: some View {
        HStack(spacing: Theme.padding) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primary.opacity(0.3),
                                AppColors.accent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "lock.open")
                    .font(AppTypography.body).fontWeight(.medium)
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock Request")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                if let message = request.message {
                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                Text(request.createdAt, style: .relative)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
                    if request.status == .pending || request.status == .queued {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.warning)
                        .frame(width: 6, height: 6)
                    Text("Pending")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.warning)
                }
            }
        }
        .padding(.vertical, Theme.spacing)
        .padding(.horizontal, Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(AppColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.primary.opacity(0.2),
                            AppColors.accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: Theme.spacing, leading: Theme.padding, bottom: Theme.spacing, trailing: Theme.padding))
    }
}
