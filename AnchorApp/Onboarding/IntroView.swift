import SwiftUI

struct IntroView: View {
    let namespace: Namespace.ID
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: AnchorTheme.Spacing.lg) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 40)
                    .fill(AnchorTheme.primary.opacity(0.25))
                    .frame(width: 200, height: 200)
                    .blur(radius: 10)
                    .matchedGeometryEffect(id: "hero", in: namespace)

                Image(systemName: "anchor.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(AnchorTheme.accent)
            }
            .padding(.bottom, AnchorTheme.Spacing.md)

            VStack(spacing: AnchorTheme.Spacing.sm) {
                Text("Anchor")
                    .font(AnchorTheme.Typography.title)
                    .foregroundColor(AnchorTheme.textPrimary)

                Text("Stay focused by tying apps to the goals you complete.")
                    .font(AnchorTheme.Typography.subtitle)
                    .foregroundColor(AnchorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            OnboardingCard {
                VStack(alignment: .leading, spacing: AnchorTheme.Spacing.sm) {
                    bullet("Block distractions with Screen Time")
                    bullet("Unlock apps by completing goals")
                    bullet("Reset daily and build consistency")
                }
            }

            Spacer()

            PrimaryButton(title: "Get Started", action: onContinue)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(spacing: AnchorTheme.Spacing.sm) {
            Circle()
                .fill(AnchorTheme.accent)
                .frame(width: 6, height: 6)
            Text(text)
                .font(AnchorTheme.Typography.body)
                .foregroundColor(AnchorTheme.textPrimary)
        }
    }
}
