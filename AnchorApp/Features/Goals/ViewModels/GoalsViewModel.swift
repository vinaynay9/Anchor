import Foundation
import Shared

@MainActor
final class GoalsViewModel: ObservableObject {
    @Published var goals: [Shared.Goal] = []
    @Published var progress: DailyGoalProgress = DailyGoalProgress(date: "")
    @Published var isAnchored: Bool = false
    @Published var completionFeedback: String?

    // Add goal sheet state
    @Published var showAddGoalSheet = false
    @Published var newGoalTitle = ""
    @Published var newGoalCategory: GoalCategory = .other

    private let dailyGoalService = DailyGoalService.shared

    var completedCount: Int {
        progress.completedGoalIds.count
    }

    var totalCount: Int {
        max(goals.count, 0)
    }

    var progressText: String {
        "\(completedCount) of \(max(totalCount, 0)) goals completed"
    }

    func load() async {
        goals = await dailyGoalService.loadGoals()
        progress = dailyGoalService.loadProgress()
        isAnchored = dailyGoalService.isAnchored()
    }

    func complete(goal: Shared.Goal) async {
        let previousCompletion = progress.lastCompletionTimestamp
        progress = await dailyGoalService.markGoalCompleted(goalId: goal.id)
        isAnchored = dailyGoalService.isAnchored()

        if let previous = previousCompletion, Date().timeIntervalSince(previous) < 120 {
            completionFeedback = "Be honest—future you will know."
        } else {
            completionFeedback = "Proud of you. Keep going."
        }
    }

    func isGoalCompleted(_ goal: Shared.Goal) -> Bool {
        progress.completedGoalIds.contains(goal.id)
    }

    func delete(goal: Shared.Goal) async {
        await dailyGoalService.removeGoal(id: goal.id)
        await load()
    }

    func addGoalFromSheet() async {
        let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        await dailyGoalService.addGoal(title: title, category: newGoalCategory)
        newGoalTitle = ""
        newGoalCategory = .other
        showAddGoalSheet = false
        await load()
    }

    func resetProgress() {
        AppGroupStorage.shared.setDailyGoalProgress(nil)
        progress = dailyGoalService.loadProgress()
    }
}

// MARK: - UserHeaderViewModel
// Moved here from Features/Shared/Views/UserHeaderView.swift so it compiles
// as part of the main AnchorApp target (that file is not in Xcode project).
// Used by SessionHomeView and GoalsListView.

@MainActor
final class UserHeaderViewModel: ObservableObject {
    @Published var firstName: String = "there"
    @Published var initials: String = "?"
    @Published var streak: Int = 0

    private let storage = AppGroupStorage.shared
    private let aggregateService = AggregateService.shared

    func load() {
        let personal = storage.getPersonalInfo()
        if let first = personal?.firstName, !first.isEmpty {
            firstName = first
            let lastInitial = personal?.lastName.first.map(String.init) ?? ""
            initials = (String(first.prefix(1)) + lastInitial).uppercased()
        } else if let profile = storage.getProfile(), !profile.displayName.isEmpty {
            firstName = profile.displayName.components(separatedBy: " ").first ?? profile.displayName
            initials = String(profile.displayName.prefix(2)).uppercased()
        }
        streak = aggregateService.currentStreak()
    }
}

// MARK: - UserHeaderView
// Subtle custom nav bar: initials circle + first name + 🔥 streak badge.
// Shown at top of Session (tab 0) and Goals (tab 1).

import SwiftUI

struct UserHeaderView: View {
    let firstName: String
    let initials: String
    let streak: Int

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(initials)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.onPrimary)
                )

            Text(firstName)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                Text("🔥").font(.system(size: 14))
                Text("\(streak)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(streak > 0 ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(streak > 0 ? .ultraThinMaterial : AnyShapeStyle(AppColors.surface.opacity(0.40)))
                    .overlay(Capsule().stroke(
                        streak > 0 ? AppColors.accent.opacity(0.30) : AppColors.border.opacity(0.30),
                        lineWidth: 1
                    ))
            )
        }
        .padding(.horizontal, Theme.spacing3)
        .padding(.top, 52)
        .padding(.bottom, Theme.spacing)
        .background(AppColors.brandBackgroundDark.opacity(0.95))
    }
}
