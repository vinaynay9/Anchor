import SwiftUI

struct OnboardingCompleteView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: AnchorTheme.Spacing.lg) {
            Spacer()

            OnboardingCard {
                VStack(spacing: AnchorTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AnchorTheme.accent)

                    Text("You’re ready")
                        .font(AnchorTheme.Typography.title)
                        .foregroundColor(AnchorTheme.textPrimary)

                    Text("Set goals, choose apps, and Anchor will keep you focused.")
                        .font(AnchorTheme.Typography.subtitle)
                        .foregroundColor(AnchorTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            PrimaryButton(title: "Continue to Anchor", action: onContinue)
        }
    }
}
