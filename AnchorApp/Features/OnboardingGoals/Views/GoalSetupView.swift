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

                    Button(action: onNext) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPressableButtonStyle())
                    .disabled(!viewModel.isValid)
                    .padding(.horizontal, Theme.spacing3)
                }
                .padding(.vertical, Theme.spacing4)
            }
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
        VStack(spacing: Theme.spacing) {
            HStack(spacing: Theme.spacing2) {
                TextField("Goal title", text: draft.title)
                    .textFieldStyle(AppTextFieldStyle())
                    .frame(maxWidth: .infinity)

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
                .frame(maxWidth: .infinity)
            }

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
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}
