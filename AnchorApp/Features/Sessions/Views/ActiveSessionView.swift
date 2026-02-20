import SwiftUI
import Shared

struct ActiveSessionView: View {
    let session: LockSession
    @ObservedObject var viewModel: SessionViewModel
    @StateObject private var goalsViewModel = GoalViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                    
                    // Anchored Timeline
                    sessionTimelineSection
                    
                    Spacer(minLength: Theme.spacing4)
                    
                }
                .padding(Theme.spacing2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            goalsViewModel.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalsUpdated)) { _ in
            goalsViewModel.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appGroupDidUpdate)) { notification in
            // Reload session to get updated events when storage updates
            if let key = notification.object as? String, key.contains("sessionEvents") {
                viewModel.loadActiveSession()
            }
            Task {
                _ = try? await SessionService.shared.getActiveSession()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: Theme.spacing) {
            Text("Anchored")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            // Status indicator dot
            HStack(spacing: Theme.smallSpacing) {
                if reduceMotion {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 8, height: 8)
                } else {
                    BreathingDotView()
                }
                Text("Anchored Mode")
                    .font(AppTypography.helper)
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
                Text("Anchored for:")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(formatElapsedTime(from: session.startTime, to: context.date))
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacing3)
        }
    }
    
    // MARK: - Daily Goals Section
    private var dailyGoalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Today's Goals")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            if goalsViewModel.goals.isEmpty {
                emptyGoalsView
            } else {
                goalsList
            }
        }
    }
    
    private var emptyGoalsView: some View {
        VStack(spacing: Theme.spacing) {
            Image(systemName: "checkmark.circle")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
            Text("No goals set")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacing3)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    private var goalsList: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(goalsViewModel.goals) { goal in
                GoalRowView(goal: goal) {
                    goalsViewModel.toggleGoal(goal)
                }
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Progress Summary
    private var progressSummarySection: some View {
        Text("Apps unlock when all goals are complete.")
            .font(AppTypography.helper)
            .foregroundColor(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, Theme.spacing2)
    }
    
    // MARK: - Anchored Timeline
    private var sessionTimelineSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Anchored Timeline")
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Theme.spacing2)
            
            VStack(alignment: .leading, spacing: 0) {
                SessionTimelineView(events: session.events)
            }
            .padding(Theme.spacing2)
            .background(AppColors.surface)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, Theme.spacing2)
        }
    }
    
    // MARK: - Helper Methods
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: Theme.spacing2) {
            Button(action: {
                HapticFeedback.selectionChanged()
                if !reduceMotion {
                    withAnimation(AppMotion.gentleSpring) {
                        checkmarkScale = 0.92
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(AppMotion.gentleSpring) {
                            checkmarkScale = 1.0
                        }
                    }
                    withAnimation(AppMotion.snappy) {
                        highlightOpacity = 0.16
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(AppMotion.snappy) {
                            highlightOpacity = 0.0
                        }
                    }
                }
                onToggle()
            }) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(AppTypography.sectionHeader)
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
                .fill(AppColors.accent.opacity(highlightOpacity))
        )
        .contentShape(Rectangle())
    }
}
