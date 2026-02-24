import SwiftUI

struct SignInView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let onContinue: () -> Void
    @StateObject private var emailAuthViewModel = EmailAuthViewModel()
    @State private var mode: AuthMode = .signIn

    private enum AuthMode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }

    private var isSignedIn: Bool { authViewModel.currentUser != nil }

    var body: some View {
        VStack(spacing: AnchorTheme.Spacing.lg) {
            Spacer()

            VStack(spacing: AnchorTheme.Spacing.sm) {
                Text("Sign in")
                    .font(AnchorTheme.Typography.title)
                    .foregroundColor(AnchorTheme.textPrimary)

                Text("Use your account to sync progress and settings.")
                    .font(AnchorTheme.Typography.subtitle)
                    .foregroundColor(AnchorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            OnboardingCard {
                VStack(spacing: AnchorTheme.Spacing.sm) {
                    Picker("Auth Mode", selection: $mode) {
                        ForEach(AuthMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mode == .signIn {
                        EmailSignInView(viewModel: emailAuthViewModel) { user in
                            authViewModel.handleAuthenticatedUser(user)
                        }
                    } else {
                        EmailSignUpView(viewModel: emailAuthViewModel) { user in
                            authViewModel.handleAuthenticatedUser(user)
                        }
                    }
                }
            }

            if let error = emailAuthViewModel.errorMessage {
                Text(error)
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(AppColors.error)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onContinue, disabled: !isSignedIn)
        }
    }
}
