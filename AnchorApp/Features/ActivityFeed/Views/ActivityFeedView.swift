import SwiftUI
import Shared

struct ActivityFeedView: View {
    @StateObject private var viewModel = ActivityFeedViewModel()
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Theme.spacing2)
                    .padding(.top, Theme.spacing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                if viewModel.isLoading && viewModel.events.isEmpty {
                    LoadingView(message: "Loading activity...")
                } else if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    activityFeedList
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshActivityFeed()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                viewModel.loadActivityFeed()
            }
        }
        .refreshable {
            viewModel.refreshActivityFeed()
        }
    }
    
    // MARK: - Activity Feed List
    
    private var activityFeedList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacing2) {
                ForEach(viewModel.groupedEvents, id: \.sectionTitle) { group in
                    VStack(alignment: .leading, spacing: Theme.spacing) {
                        // Section Header
                        Text(group.sectionTitle)
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, Theme.spacing2)
                            .padding(.top, Theme.spacing2)
                        
                        // Events in Section
                        ForEach(group.events) { event in
                            ActivityEventRowView(
                                event: event,
                                viewModel: viewModel
                            )
                            .padding(.horizontal, Theme.spacing2)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        Spacer()
                    }
                    .padding(Theme.spacing3)
                }
            }
            .padding(.bottom, Theme.spacing2)
        }
        .animation(Theme.springAnimation, value: viewModel.events.count)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "bell.slash",
            title: "No activity yet",
            message: "Activity from your accountability network will appear here",
            actionTitle: nil,
            action: nil
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Activity Event Row View

struct ActivityEventRowView: View {
    let event: FriendActivityEvent
    @ObservedObject var viewModel: ActivityFeedViewModel
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: Theme.spacing2) {
            // Icon with color-coded indicator
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                viewModel.getEventColor(for: event.type).opacity(0.3),
                                viewModel.getEventColor(for: event.type).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: viewModel.getEventIcon(for: event.type))
                    .font(AppTypography.body).fontWeight(.medium)
                    .foregroundColor(viewModel.getEventColor(for: event.type))
                    .scaleEffect(isPulsing && event.type == .unlockApproved ? 1.1 : 1.0)
            }
            .onAppear {
                // Pulse animation for unlock approvals
                if event.type == .unlockApproved {
                    withAnimation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
            }
            
            // Event Details
            VStack(alignment: .leading, spacing: Theme.smallSpacing) {
                Text(viewModel.getEventTitle(for: event.type, friendName: viewModel.getFriendName(for: event.friendId)))
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                
                if let metadata = event.metadata, let message = metadata["message"], !message.isEmpty {
                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                
                Text(event.timestamp.timeAgo())
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(AppColors.secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(
                    LinearGradient(
                        colors: [
                            viewModel.getEventColor(for: event.type).opacity(0.2),
                            viewModel.getEventColor(for: event.type).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

