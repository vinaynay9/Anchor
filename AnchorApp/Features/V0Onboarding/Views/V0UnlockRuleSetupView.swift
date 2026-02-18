import SwiftUI
import Shared

struct V0UnlockRuleSetupView: View {
    @State private var selectedMode: V0UnlockMode = .unlockAppsWhenAllTasksDone
    @State private var selectedMinutes: Int = 15
    @State private var selectedPercent: Int = 25

    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlock rules")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Choose how goals unlock your apps.")
                .foregroundColor(AppColors.textSecondary)

            Picker("Unlock mode", selection: $selectedMode) {
                ForEach(V0UnlockMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.inline)
            .tint(AppColors.accent)

            Text("Unlock duration")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            Picker("Minutes", selection: $selectedMinutes) {
                ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { value in
                    Text("\(value) min").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            if selectedMode == .unlockFixedTimePerPercentCompleted {
                Text("Percent step")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                Picker("Percent", selection: $selectedPercent) {
                    ForEach([25, 50, 75, 100], id: \.self) { value in
                        Text("\(value)%").tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button(action: saveAndContinue) {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 12)

            Spacer()
        }
        .padding()
        .applyV0Theme()
    }

    private func saveAndContinue() {
        let config = V0UnlockConfig(
            mode: selectedMode,
            timeIntervalMinutes: selectedMinutes,
            percentStep: selectedPercent
        )
        AppGroupStorage.shared.setV0UnlockConfig(config)
        onContinue()
    }
}
