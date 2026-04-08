import SwiftUI
import Shared

struct GoalCompletionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let goal: Shared.Goal
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppColors.brandBackgroundDark.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: Theme.spacing5)

                // Category pill + title
                VStack(spacing: Theme.spacing2) {
                    CategoryPill(category: goal.category)

                    Text(goal.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacing3)
                }

                Spacer().frame(height: Theme.spacing4)

                // Assertion card
                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.accent.opacity(0.85))
                        Text("Confirmation required")
                            .font(AppTypography.sectionHeader)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Text("I assert that I have completed this goal.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(3)

                    Text("Only confirm if you truly did it. Anchor works on honesty.")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary.opacity(0.70))
                        .lineSpacing(2)
                        .padding(.top, 2)
                }
                .padding(Theme.spacing3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                .stroke(AppColors.accent.opacity(0.30), lineWidth: 1)
                        )
                )
                .padding(.horizontal, Theme.spacing3)

                Spacer()

                // Buttons
                VStack(spacing: Theme.spacing2) {
                    Button {
                        HapticFeedback.success()
                        onComplete()
                        dismiss()
                    } label: {
                        Text("Confirm — I Did It")
                            .font(AppTypography.button)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                        .fill(AppColors.accent)
                                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                        .fill(LinearGradient(
                                            colors: [Color.white.opacity(0.12), .clear],
                                            startPoint: .top, endPoint: .bottom
                                        ))
                                }
                                .shadow(color: AppColors.accent.opacity(0.45), radius: 16, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(AppTypography.button)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                            .stroke(AppColors.border.opacity(0.45), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.horizontal, Theme.spacing3)
                .padding(.bottom, 36)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppColors.brandBackgroundDark)
    }
}

// MARK: - Category pill (shared)

struct CategoryPill: View {
    let category: GoalCategory

    var body: some View {
        Text(category.displayName)
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .foregroundColor(pillTextColor)
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(
                Capsule().fill(pillColor.opacity(0.22))
                    .overlay(Capsule().stroke(pillColor.opacity(0.45), lineWidth: 1))
            )
    }

    var pillColor: Color {
        switch category {
        case .fitness:       return .green
        case .health:        return .mint
        case .mentalHealth:  return .purple
        case .work:          return .blue
        case .skillDevelopment: return .cyan
        case .learning:      return .indigo
        case .school:        return .orange
        case .career:        return .teal
        case .finance:       return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .relationships: return .pink
        case .creativity:    return .yellow
        case .home:          return Color(red: 0.8, green: 0.6, blue: 0.3)
        case .other:         return .gray
        }
    }

    var pillTextColor: Color {
        pillColor
    }
}
