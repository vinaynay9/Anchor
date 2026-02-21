import SwiftUI

struct OnboardingPagerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = 0

    let onLogin: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            TabView(selection: $selection) {
                OnboardingPageView(
                    title: "What is Anchor?",
                    bodyText: "Anchor helps you eliminate distractions and work toward your daily goals.",
                    iconName: nil
                ) {
                    LoopingVideoView(resourceName: "Anchor_demo_AI", fileExtension: "mov")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Theme.spacing3)
                        .padding(.top, Theme.spacing)
                } footer: {
                    VStack(spacing: Theme.spacing) {
                        Text("Swipe to continue →")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.onboardingHintText)
                    }
                }
                .tag(0)

                OnboardingPageView(
                    title: "How does it work?",
                    bodyText: nil,
                    iconName: "list.bullet.rectangle"
                ) {
                    VStack(spacing: Theme.spacing2) {
                        stepRow("1", "Set daily goals (Duolingo, workout, cook a meal, networking, etc.)")
                        stepRow("2", "Your phone locks automatically each night for tomorrow.")
                        stepRow("3", "Mark goals complete to earn Screen Time.")
                    }
                }
                .tag(1)

                OnboardingPageView(
                    title: "Why Anchor",
                    bodyText: "We prioritize getting sh*t done. Let Anchor help you do the same.",
                    iconName: "bolt.fill"
                ) {
                    Button(action: onLogin) {
                        Text("Log in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPressableButtonStyle())
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(AppMotion.animation(AppMotion.standard, reduceMotion: reduceMotion), value: selection)
        }
    }

    private func stepRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacing2) {
            Text(number)
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.accent)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.onboardingBodyText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(Theme.spacing2)
        .background(AppColors.surface)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}
