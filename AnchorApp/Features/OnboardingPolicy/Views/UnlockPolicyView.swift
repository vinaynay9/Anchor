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
                            mode: .unlockAppsWhenAllTasksDone
                        )

                        policyOption(
                            title: "Unlock a fixed time per goal completed",
                            mode: .unlockFixedTimePerGoal
                        )

                        if viewModel.selectedMode == .unlockFixedTimePerGoal {
                            minutesPicker(title: "Minutes per goal", selection: $viewModel.minutesPerGoal)
                        }

                        policyOption(
                            title: "Unlock a fixed time per % of goals completed",
                            mode: .unlockFixedTimePerPercentCompleted
                        )

                        if viewModel.selectedMode == .unlockFixedTimePerPercentCompleted {
                            percentPicker
                            minutesPicker(title: "Minutes per %", selection: $viewModel.minutesPerPercent)
                        }

                        policyOption(
                            title: "Unlock a fixed set of apps for a fixed time per goal completed",
                            mode: .unlockFixedAppsPerGoalCompletedForFixedTime
                        )

                        if viewModel.selectedMode == .unlockFixedAppsPerGoalCompletedForFixedTime {
                            minutesPicker(title: "Minutes per goal", selection: $viewModel.fixedTimeMinutes)
                        }
                    }
                    .padding(.horizontal, Theme.spacing3)

                    Button(action: {
                        onNext(viewModel.buildConfig())
                    }) {
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
        .motion(AppMotion.standard, reduceMotion: reduceMotion, value: viewModel.selectedMode)
    }

    private var header: some View {
        VStack(spacing: Theme.spacing2) {
            Text("Choose how you earn screen time")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.spacing3)
    }

    private func policyOption(title: String, mode: UnlockPolicyMode) -> some View {
        Button(action: {
            viewModel.selectedMode = mode
        }) {
            HStack(spacing: Theme.spacing2) {
                Image(systemName: viewModel.selectedMode == mode ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(viewModel.selectedMode == mode ? AppColors.accent : AppColors.textTertiary)
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(Theme.spacing2)
            .background(AppColors.surface)
            .cornerRadius(Theme.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func minutesPicker(title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text(title)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)

            Menu {
                ForEach(viewModel.minuteOptions, id: \.self) { value in
                    Button("\(value) minutes") {
                        selection.wrappedValue = value
                    }
                }
            } label: {
                HStack {
                    Text("\(selection.wrappedValue) minutes")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, Theme.spacing2)
                .padding(.horizontal, Theme.spacing2)
                .background(AppColors.surface)
                .cornerRadius(Theme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
        }
    }

    private var percentPicker: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            Text("Percent milestone")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)

            Menu {
                ForEach(viewModel.percentOptions, id: \.self) { value in
                    Button("\(value)%") {
                        viewModel.percentThreshold = value
                    }
                }
            } label: {
                HStack {
                    Text("\(viewModel.percentThreshold)%")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, Theme.spacing2)
                .padding(.horizontal, Theme.spacing2)
                .background(AppColors.surface)
                .cornerRadius(Theme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
        }
    }
}
