import SwiftUI
import Shared

struct UnlockPolicyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject var viewModel: UnlockPolicyViewModel

    let onNext: (UnlockPolicyConfig) -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacing3) {
                    header

                    VStack(spacing: Theme.spacing2) {
                        policyOption(
                            title: "Unlock apps when all goals are done",
                            subtitle: "No partial unlocks until everything is complete.",
                            mode: .unlockAppsWhenAllTasksDone
                        )

                        policyOption(
                            title: "Unlock a fixed time per goal completed",
                            subtitle: "Earn a set number of minutes for each goal.",
                            mode: .unlockFixedTimePerGoal
                        )

                        if viewModel.selectedMode == .unlockFixedTimePerGoal {
                            optionCard {
                                minutesChips(title: "Minutes per goal", selection: $viewModel.minutesPerGoal)
                            }
                        }

                        policyOption(
                            title: "Unlock a fixed time per % of goals completed",
                            subtitle: "Earn minutes when you hit milestones.",
                            mode: .unlockFixedTimePerPercentCompleted
                        )

                        if viewModel.selectedMode == .unlockFixedTimePerPercentCompleted {
                            optionCard {
                                percentChips
                                minutesChips(title: "Minutes per milestone", selection: $viewModel.minutesPerPercent)
                            }
                        }

                        policyOption(
                            title: "Unlock a fixed set of apps for a fixed time per goal completed",
                            subtitle: "Earn access to specific apps per goal.",
                            mode: .unlockFixedAppsPerGoalCompletedForFixedTime
                        )

                        if viewModel.selectedMode == .unlockFixedAppsPerGoalCompletedForFixedTime {
                            optionCard {
                                minutesChips(title: "Minutes per goal", selection: $viewModel.fixedTimeMinutes)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacing3)
                }
                .padding(.vertical, Theme.spacing4)
                .padding(.bottom, Theme.spacing5)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.spacing) {
                Button(action: {
                    onNext(viewModel.buildConfig())
                }) {
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
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.selectedMode)
    }

    private var header: some View {
        VStack(spacing: Theme.spacing2) {
            Text("Choose how you earn screen time")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.onboardingTitleText)
                .multilineTextAlignment(.center)

            Text("Pick the reward rule that feels fair and motivating.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.onboardingBodyText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacing3)
    }

    private func policyOption(title: String, subtitle: String, mode: UnlockPolicyMode) -> some View {
        Button(action: {
            viewModel.selectedMode = mode
        }) {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                HStack(spacing: Theme.spacing2) {
                    Image(systemName: viewModel.selectedMode == mode ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(viewModel.selectedMode == mode ? AppColors.accent : AppColors.textTertiary)
                    Text(title)
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.onboardingTitleText)
                    Spacer()
                }

                Text(subtitle)
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.onboardingBodyText)
            }
            .padding(Theme.spacing2)
            .background(AppColors.surface)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(viewModel.selectedMode == mode ? AppColors.accent.opacity(0.5) : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }

    private func optionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            content()
        }
        .padding(Theme.spacing2)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private func minutesChips(title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(title)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.onboardingBodyText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: Theme.spacing)], spacing: Theme.spacing) {
                ForEach(viewModel.minuteOptions, id: \.self) { value in
                    Button(action: {
                        selection.wrappedValue = value
                    }) {
                        Text("\(value)m")
                            .font(AppTypography.helper)
                            .foregroundColor(selection.wrappedValue == value ? AppColors.onPrimary : AppColors.onboardingBodyText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacing)
                            .background(
                                Capsule()
                                    .fill(selection.wrappedValue == value ? AppColors.accent : AppColors.surface)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("\(value) minutes")
                }
            }
        }
    }

    private var percentChips: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Percent milestone")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.onboardingBodyText)

            HStack(spacing: Theme.spacing) {
                ForEach(viewModel.percentOptions, id: \.self) { value in
                    Button(action: {
                        viewModel.percentThreshold = value
                    }) {
                        Text("\(value)%")
                            .font(AppTypography.helper)
                            .foregroundColor(viewModel.percentThreshold == value ? AppColors.onPrimary : AppColors.onboardingBodyText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacing)
                            .background(
                                Capsule()
                                    .fill(viewModel.percentThreshold == value ? AppColors.accent : AppColors.surface)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("\(value) percent")
                }
            }
        }
    }
}
