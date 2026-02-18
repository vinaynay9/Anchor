import SwiftUI
import Shared

struct V0GoalCompleteView: View {
    let goal: V0Goal

    @Environment(\.dismiss) private var dismiss
    @State private var isCompleteChecked = false
    @State private var affirmationText = ""
    @State private var errorMessage: String?

    private let requiredPhrase = "I affirm that I have completed this goal"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(goal.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Toggle("Mark complete", isOn: $isCompleteChecked)
                .tint(AppColors.accent)

            Text("Type the affirmation to complete:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            TextField(requiredPhrase, text: $affirmationText)
                .textFieldStyle(AppTextFieldStyle())

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textTertiary)
            }

            Button(action: completeGoal) {
                Text("Confirm completion")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isReady)
            .opacity(isReady ? 1.0 : 0.6)

            Spacer()
        }
        .padding()
        .applyV0Theme()
    }

    private var isReady: Bool {
        isCompleteChecked && affirmationTextMatches
    }

    private var affirmationTextMatches: Bool {
        affirmationText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == requiredPhrase.lowercased()
    }

    private func completeGoal() {
        guard isReady else {
            errorMessage = "Please check the box and type the exact phrase."
            return
        }

        V0GoalService.shared.markGoalCompletedToday(goal.id)
        V0UnlockPolicyService.shared.handleGoalCompletion(goalId: goal.id)
        dismiss()
    }
}
