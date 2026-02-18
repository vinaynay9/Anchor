import SwiftUI
import Shared

struct V0AuthEntryView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onSignedIn: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome to Anchor")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Sign in to set goals and control Screen Time.")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button(action: signInWithApple) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(isLoading ? "Signing In..." : "Sign in with Apple")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            .padding(.horizontal, 24)

            Spacer()
        }
        .applyV0Theme()
    }

    private func signInWithApple() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await AuthService.shared.signInWithApple()
                await MainActor.run {
                    isLoading = false
                    onSignedIn()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Sign in failed. Please try again."
                }
            }
        }
    }
}
