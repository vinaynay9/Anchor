import SwiftUI

struct OnboardingPagerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection = 0
    @State private var animateBoat = false
    @State private var animateChecklist = false
    @State private var animateChart = false

    let onLogin: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            TabView(selection: $selection) {
                OnboardingPageView(
                    title: "What is Anchor?",
                    bodyText: "Anchor helps you eliminate distractions and work toward your goals.",
                    iconName: nil
                ) {
                    GeometryReader { proxy in
                        let targetHeight = min(320, max(240, proxy.size.height * 0.32))
                        LoopingVideoView(resourceName: "Anchor_demo_AI", fileExtension: "mov")
                            .frame(maxWidth: .infinity, maxHeight: targetHeight)
                            .padding(.horizontal, Theme.spacing3)
                            .padding(.top, Theme.spacing)
                    }
                    .frame(height: 320)
                } footer: {
                    VStack(spacing: Theme.spacing) {
                        Text("Swipe to continue →")
                            .font(AppTypography.helper)
                            .foregroundColor(AppColors.onboardingHintText)
                    }
                }
                .tag(0)
                .overlay(alignment: .topTrailing) {
                    OnboardingIconHeader {
                        Image(systemName: "sailboat.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                            .offset(y: animateBoat ? 6 : 0)
                            .opacity(animateBoat ? 0.95 : 1)
                    }
                }

                OnboardingPageView(
                    title: "How does it work?",
                    bodyText: nil,
                    iconName: nil
                ) {
                    VStack(spacing: Theme.spacing2) {
                        stepRow("1", "Set daily goals (Duolingo, working out, cooking a meal, networking).")
                        stepRow("2", "Your phone locks automatically each night for tomorrow.")
                        stepRow("3", "Mark goals complete to earn Screen Time.")
                    }
                }
                .tag(1)
                .overlay(alignment: .topTrailing) {
                    OnboardingIconHeader {
                        ZStack {
                            Image(systemName: "square")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(AppColors.accent.opacity(0.35))
                                .opacity(animateChecklist ? 0 : 1)

                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                                .opacity(animateChecklist ? 1 : 0)
                        }
                    }
                }

                OnboardingPageView(
                    title: "Why Anchor",
                    bodyText: nil,
                    iconName: nil
                ) {
                    VStack(spacing: Theme.spacing) {
                        VStack(spacing: 4) {
                            Text("We prioritize getting sh*t done.")
                            Text("Let us help you do the same.")
                        }
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.onboardingTitleText)
                        .multilineTextAlignment(.center)

                        Text("See your productivity explode.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.onboardingHintText)
                    }
                    .padding(.horizontal, Theme.spacing3)

                    Button(action: onLogin) {
                        Text("Log in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryPressableButtonStyle())
                }
                .tag(2)
                .overlay(alignment: .topTrailing) {
                    OnboardingIconHeader {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(AppColors.accent)
                            .scaleEffect(animateChart ? 1.05 : 1)
                            .opacity(animateChart ? 1 : 0.92)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(AppMotion.animation(AppMotion.standard, reduceMotion: reduceMotion), value: selection)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(AppMotion.standard.speed(0.12).repeatForever(autoreverses: true)) {
                animateBoat = true
            }
            withAnimation(AppMotion.standard.speed(0.2).repeatForever(autoreverses: true)) {
                animateChecklist = true
            }
            withAnimation(AppMotion.standard.speed(0.18).repeatForever(autoreverses: true)) {
                animateChart = true
            }
        }
    }

    private func stepRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacing2) {
            Text(number)
                .font(AppTypography.sectionHeader)
                .foregroundColor(AppColors.accent)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.helper)
                .foregroundColor(AppColors.onboardingBodyText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(Theme.spacing2)
        .background(AppColors.surfaceElevated)
        .cornerRadius(Theme.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.accent.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}
