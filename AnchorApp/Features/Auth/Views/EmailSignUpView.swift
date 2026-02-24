import SwiftUI
import Shared

struct EmailSignUpView: View {
    @ObservedObject var viewModel: EmailAuthViewModel
    let onSuccess: (User) -> Void

    @State private var showEmailError = false
    @State private var showPasswordError = false
    @State private var showConfirmError = false

    private var shouldShowPasswordField: Bool {
        viewModel.isEmailValid
    }

    private var shouldShowConfirmField: Bool {
        viewModel.isEmailValid && viewModel.isPasswordValid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Create account")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)

            VStack(alignment: .leading, spacing: Theme.spacing) {
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .textFieldStyle(AppTextFieldStyle())
                    .accessibilityLabel("Email")
                    .onChange(of: viewModel.email) { _ in
                        showEmailError = !viewModel.email.isEmpty && !viewModel.isEmailValid
                    }

                if showEmailError {
                    Text("Enter a valid email address.")
                        .font(AppTypography.helper)
                        .foregroundColor(AppColors.error)
                }

                if shouldShowPasswordField {
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .textFieldStyle(AppTextFieldStyle())
                        .accessibilityLabel("Password")
                        .onChange(of: viewModel.password) { _ in
                            showPasswordError = !viewModel.password.isEmpty && !viewModel.isPasswordValid
                        }

                    if showPasswordError {
                        Text("Password must be 8+ characters with a letter, number, and symbol.")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.error)
                    }
                }

                if shouldShowConfirmField {
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .textFieldStyle(AppTextFieldStyle())
                        .accessibilityLabel("Confirm password")
                        .onChange(of: viewModel.confirmPassword) { _ in
                            showConfirmError = !viewModel.confirmPassword.isEmpty && !viewModel.isConfirmValid
                        }

                    if showConfirmError {
                        Text("Passwords do not match.")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.error)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.error)
            }

            Button(action: {
                Task {
                    if let user = await viewModel.signUp() {
                        onSuccess(user)
                    }
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.onPrimary)
                } else {
                    Text("Create Account")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canSignUp)
            .accessibilityLabel("Create account with email and password")
        }
    }
}
