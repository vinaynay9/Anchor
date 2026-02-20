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

                Image("Anchor_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
            }
            .padding(.bottom, AnchorTheme.Spacing.md)

            VStack(spacing: AnchorTheme.Spacing.sm) {
                Text("Anchor")
                    .font(AnchorTheme.Typography.title)
                    .foregroundColor(AnchorTheme.textPrimary)

                Text("Lock apps. Set goals. Stay Anchored.")
                    .font(AnchorTheme.Typography.subtitle)
                    .foregroundColor(AnchorTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            OnboardingCard {
                VStack(alignment: .leading, spacing: AnchorTheme.Spacing.sm) {
                    bullet("Lock selected apps until goals are complete")
                    bullet("Anchor your day with daily goals")
                    bullet("Break Anchor when all goals are done")
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
