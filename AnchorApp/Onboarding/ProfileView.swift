import SwiftUI

struct ProfileView: View {
    @State private var displayName: String = ""
    @State private var birthMonth: Int = 1
    @State private var birthDay: Int = 1
    @State private var timezone: String = TimeZone.current.identifier
    @State private var showError: Bool = false

    let onContinue: (String, Int, Int, String) -> Void

    var body: some View {
        VStack(spacing: AnchorTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AnchorTheme.Spacing.sm) {
                Text("Your profile")
                    .font(AnchorTheme.Typography.title)
                    .foregroundColor(AnchorTheme.textPrimary)

                Text("We use this to personalize your experience.")
                    .font(AnchorTheme.Typography.subtitle)
                    .foregroundColor(AnchorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            OnboardingCard {
                VStack(alignment: .leading, spacing: AnchorTheme.Spacing.md) {
                    TextField("Display name", text: $displayName)
                        .textFieldStyle(AppTextFieldStyle())

                    HStack(spacing: AnchorTheme.Spacing.sm) {
                        Picker("Month", selection: $birthMonth) {
                            ForEach(1...12, id: \ .self) { month in
                                Text("\(month)").tag(month)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Day", selection: $birthDay) {
                            ForEach(1...31, id: \ .self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextField("Timezone", text: $timezone)
                        .textFieldStyle(AppTextFieldStyle())
                }
            }

            if showError {
                Text("Please enter a valid name and date.")
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(AppColors.error)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: validateAndContinue)
        }
    }

    private func validateAndContinue() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 50, ProfileValidation.isValidBirthDate(month: birthMonth, day: birthDay) else {
            showError = true
            return
        }
        showError = false
        onContinue(trimmed, birthMonth, birthDay, timezone)
    }
}
