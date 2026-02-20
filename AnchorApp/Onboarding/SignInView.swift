import SwiftUI

struct SignInView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let onContinue: () -> Void

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
                    Button {
                        authViewModel.signInWithApple()
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Continue with Apple")
                                .font(AnchorTheme.Typography.body)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        // TODO: Wire Google Sign-In when available
                    } label: {
                        Text("Continue with Google (Coming soon)")
                            .font(AnchorTheme.Typography.body)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(true)
                }
            }

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(AnchorTheme.Typography.caption)
                    .foregroundColor(.red)
            }

            Spacer()

            PrimaryButton(title: "Continue", action: onContinue, disabled: !isSignedIn)
        }
    }
}
