import SwiftUI
import Shared

struct GoalCompletionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var affirmationText = ""
    @State private var showValidation = false

    let goal: Shared.Goal
    let onComplete: () -> Void

    private let affirmationPhrase = "I affirm that I have completed this goal"

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: Theme.spacing3) {
                Text(goal.title)
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Only confirm if you truly did it. This is how Anchor works.")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: Theme.spacing2) {
                    Text("Type to confirm")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textPrimary)

                    TextField(affirmationPhrase, text: $affirmationText)
                        .textFieldStyle(AppTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    if showValidation && !isValid {
                        Text("Enter the exact phrase to continue.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.accent)
                    }
                }

                Button(action: submit) {
                    Text("Mark Complete")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPressableButtonStyle())
                .disabled(!isValid)

                Spacer()
            }
            .padding(.horizontal, Theme.spacing3)
            .padding(.vertical, Theme.spacing4)
        }
    }

    private var isValid: Bool {
        affirmationText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == affirmationPhrase.lowercased()
    }

    private func submit() {
        if !isValid {
            showValidation = true
            return
        }
        onComplete()
        dismiss()
    }
}
