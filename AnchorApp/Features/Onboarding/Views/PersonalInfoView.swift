import SwiftUI

struct PersonalInfoView: View {
    @ObservedObject var onboardingViewModel: OnboardingViewModel
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var errorMessage: String?

    let onContinue: () -> Void

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: Theme.spacing4) {
            Spacer()

            VStack(spacing: Theme.spacing2) {
                Text("Personal info")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.onboardingTitleText)

                Text("Tell us who you are. This helps personalize your experience.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.onboardingBodyText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }

            VStack(spacing: Theme.spacing2) {
                TextField("First name", text: $firstName)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(AppTextFieldStyle())

                TextField("Last name", text: $lastName)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(AppTextFieldStyle())

                DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(Theme.spacing2)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .fill(AppColors.surfaceElevated)
                    )
            }
            .padding(.horizontal, Theme.spacing3)

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.error)
            }

            Button(action: {
                Task {
                    let ok = await onboardingViewModel.savePersonalInfo(
                        firstName: firstName,
                        lastName: lastName,
                        birthday: birthday
                    )
                    if ok {
                        errorMessage = nil
                        onContinue()
                    } else {
                        errorMessage = "Could not save your profile. Please try again."
                    }
                }
            }) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isValid)
            .padding(.horizontal, Theme.spacing3)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}
