import SwiftUI

struct V0ResetTimeView: View {
    @ObservedObject var viewModel: V0SettingsViewModel

    @State private var selectedHour: Int = 0
    @State private var confirmationText: String = ""
    @State private var errorMessage: String?

    private let frictionPhrase = "I know I am destroying my habits by changing my time"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily reset time")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Choose when goals and locks reset each day.")
                .foregroundColor(AppColors.textSecondary)

            Picker("Reset hour", selection: $selectedHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .tint(AppColors.accent)

            if selectedHour > 0 {
                Text("Type the phrase to confirm:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                TextField(frictionPhrase, text: $confirmationText)
                    .textFieldStyle(AppTextFieldStyle())
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textTertiary)
            }

            Button("Save") {
                save()
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .padding()
        .applyV0Theme()
        .onAppear {
            selectedHour = viewModel.dailyState.dailyResetHour
        }
    }

    private func save() {
        if selectedHour > 0 {
            let matches = confirmationText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == frictionPhrase.lowercased()
            guard matches else {
                errorMessage = "Please type the exact phrase to confirm."
                return
            }
        }

        errorMessage = nil
        viewModel.updateResetTime(hour: selectedHour, minute: 0)
    }
}
