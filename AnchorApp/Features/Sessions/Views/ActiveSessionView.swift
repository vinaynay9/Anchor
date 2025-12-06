import SwiftUI
import Shared

struct ActiveSessionView: View {
    let session: LockSession
    @ObservedObject var viewModel: SessionViewModel
    @StateObject private var goalService = GoalService.shared
    @State private var goals: [Goal] = []
    @EnvironmentObject var coordinator: MainTabFlow
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    // Header with status indicator
                    headerSection
                    
                    // Elapsed time display
                    elapsedTimeSection
                    
                    // Daily Goals Checklist
                    dailyGoalsSection
                    
                    // Progress Summary
                    progressSummarySection
                    
                    // Session Timeline
                    sessionTimelineSection
                    
                    Spacer(minLength: Theme.spacing4)
                    
                    // Subtle unlock request button
                    unlockRequestButton
                }
                .padding(Theme.spacing2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGoals()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalsUpdated)) { _ in
            loadGoals()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appGroupDidUpdate)) { notification in
            // Reload session to get updated events when storage updates
            if let key = notification.object as? String, key.contains("sessionEvents") {
                viewModel.loadActiveSession()
            }
        }
            // Reload session to get updated events
            Task {
                if let updatedSession = try? await SessionService.shared.getActiveSession() {
                    // Update view model's active session if needed
                    // Note: This is a workaround - ideally SessionViewModel would observe session changes
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: Theme.spacing) {
            Text("Session Active")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Status indicator dot
            HStack(spacing: Theme.smallSpacing) {
                BreathingDotView()
                Text("Blocking Apps")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.spacing2)
        .padding(.top, Theme.spacing)
    }
    
    // MARK: - Elapsed Time Section
    private var elapsedTimeSection: some View {
        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
            VStack(spacing: Theme.spacing) {
                Text("Locked for:")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(formatElapsedTime(from: session.startTime, to: context.date))
                    .font(AppTypography.display2)
                    .foregroundColor(AppColors.anchorAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing3)
        }
    }
    
    // MARK: - Daily Goals Section
    private var dailyGoalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Today's Goals")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            if goals.isEmpty {
                emptyGoalsView
            } else {
                goalsList
            }
        }
    }
    
    private var emptyGoalsView: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            Text("No goals set")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacing3)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
        .padding(.horizontal, Theme.spacing2)
    }
    
    private var goalsList: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(goals) { goal in
                GoalRowView(goal: goal) {
                    goalService.toggleGoal(goal)
                    loadGoals()
                }
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.secondaryBackground)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppColors.anchorLavender.opacity(0.3),
                            AppColors.anchorAccent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Progress Summary
    private var progressSummarySection: some View {
        Text("Complete all goals to unlock apps.")
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Session Timeline
    private var sessionTimelineSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Session Timeline")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            VStack(alignment: .leading, spacing: 0) {
                SessionTimelineView(events: session.events)
            }
            .padding(Theme.spacing2)
            .background(AppColors.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.anchorLavender.opacity(0.3),
                                AppColors.anchorAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Unlock Request Button
    private var unlockRequestButton: some View {
        Button(action: {
            // Navigate to unlock request flow
            if let session = viewModel.activeSession {
                // Navigate to unlock request submission view via coordinator
                coordinator.navigateToUnlockRequestSubmit(session: session)
            }
        }) {
            Text("Request Unlock")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.anchorAccent)
        }
        .buttonStyle(GhostButtonStyle())
        .padding(.bottom, Theme.spacing2)
    }
    
    // MARK: - Helper Methods
    private func loadGoals() {
        goals = goalService.loadGoals()
    }
    
    private func formatElapsedTime(from startDate: Date, to currentDate: Date) -> String {
        let elapsed = currentDate.timeIntervalSince(startDate)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Goal Row View
struct GoalRowView: View {
    let goal: Goal
    let onToggle: () -> Void
    @State private var checkmarkScale: CGFloat = 1.0
    @State private var highlightOpacity: Double = 0.0
    
    var body: some View {
        HStack(spacing: Theme.spacing2) {
            Button(action: {
                HapticFeedback.soft()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkScale = 0.8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        checkmarkScale = 1.0
                    }
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    highlightOpacity = 0.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        highlightOpacity = 0.0
                    }
                }
                onToggle()
            }) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(goal.isCompleted ? AppColors.success : AppColors.textSecondary)
                    .scaleEffect(checkmarkScale)
            }
            .buttonStyle(.plain)
            
            Text(goal.name)
                .font(AppTypography.body)
                .foregroundColor(goal.isCompleted ? AppColors.textSecondary : AppColors.textPrimary)
                .strikethrough(goal.isCompleted)
            
            Spacer()
        }
        .padding(.vertical, Theme.spacing)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(AppColors.anchorLavender.opacity(highlightOpacity))
        )
        .contentShape(Rectangle())
    }
}

