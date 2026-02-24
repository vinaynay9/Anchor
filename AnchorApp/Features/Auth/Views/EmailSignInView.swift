import SwiftUI
import Shared

struct EmailSignInView: View {
    @ObservedObject var viewModel: EmailAuthViewModel
    let onSuccess: (User) -> Void

    @State private var showEmailError = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing2) {
            Text("Sign in")
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

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .textFieldStyle(AppTextFieldStyle())
                    .accessibilityLabel("Password")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.error)
            }

            Button(action: {
                Task {
                    if let user = await viewModel.signIn() {
                        onSuccess(user)
                    }
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppColors.onPrimary)
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.canSignIn)
            .accessibilityLabel("Sign in with email and password")
        }
    }
}
