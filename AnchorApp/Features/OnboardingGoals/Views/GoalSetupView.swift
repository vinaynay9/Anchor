import SwiftUI
import Shared

struct GoalSetupView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: GoalSetupViewModel

    let onNext: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.spacing2),
        GridItem(.flexible(), spacing: Theme.spacing2)
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    header

                    VStack(spacing: Theme.spacing2) {
                        ForEach($viewModel.drafts) { $draft in
                            goalRow(draft: $draft)
                        }
                    }
                    .padding(.horizontal, Theme.spacing3)

                    if viewModel.drafts.count >= viewModel.maxGoals {
                        Text("Max 7 goals. If you want more, combine a few into a bigger goal.")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.onboardingHintText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing3)
                    }

                    Button(action: { viewModel.addGoal() }) {
                        Text("Add Goal")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryPressableButtonStyle())
                    .disabled(!viewModel.canAddMore)
                    .padding(.horizontal, Theme.spacing3)
                }
                .padding(.vertical, Theme.spacing4)
                .padding(.bottom, Theme.spacing5)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.spacing) {
                Button(action: onNext) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPressableButtonStyle())
                .disabled(!viewModel.isValid)
            }
            .padding(.horizontal, Theme.spacing3)
            .padding(.vertical, Theme.spacing2)
            .background(AppColors.background.opacity(0.95))
        }
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.drafts.count)
    }

    private var header: some View {
        VStack(spacing: Theme.spacing2) {
            Text("Time to set your goals.")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.onboardingTitleText)
                .multilineTextAlignment(.center)

            Text("Remember: choose goals that push you past your current habits and improve your lifestyle.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.onboardingBodyText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing3)
        }
        .padding(.horizontal, Theme.spacing3)
    }

    private func goalRow(draft: Binding<GoalSetupViewModel.GoalDraft>) -> some View {
        let isComplete: Bool = {
            let hasTitle = !draft.wrappedValue.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasCustomCategory = !draft.wrappedValue.customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return (hasTitle && draft.wrappedValue.category != .other)
                || (draft.wrappedValue.category == .other && hasCustomCategory)
        }()

        return VStack(spacing: Theme.spacing) {
            GeometryReader { proxy in
                let spacing = Theme.spacing2
                let totalWidth = max(0, proxy.size.width - spacing)
                let leftWidth = totalWidth * 0.6
                let rightWidth = totalWidth * 0.4

                HStack(spacing: spacing) {
                    TextField("Goal title", text: draft.title)
                        .textFieldStyle(AppTextFieldStyle())
                        .frame(width: leftWidth)

                    Menu {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                draft.wrappedValue.category = category
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(draft.wrappedValue.category.displayName)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.onboardingTitleText)
                            Image(systemName: "chevron.down")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.onboardingBodyText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.spacing2)
                        .padding(.horizontal, Theme.spacing2)
                        .background(AppColors.surface)
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    }
                    .frame(width: rightWidth)
                    .accessibilityLabel("Category")
                }
            }
            .frame(height: 52)

            if draft.wrappedValue.category == .other {
                TextField("Specify category", text: draft.customCategoryName)
                    .textFieldStyle(AppTextFieldStyle())
            }
        }
        .padding(Theme.spacing2)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(isComplete ? AppColors.accent.opacity(0.6) : AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }
}
