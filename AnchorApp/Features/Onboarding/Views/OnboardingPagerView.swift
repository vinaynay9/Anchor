import SwiftUI

// MARK: - Onboarding Pager
// Full-screen 4-page welcome flow with glass morphism, floating elements,
// staggered animations and smooth swipe transitions.

struct OnboardingPagerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0

    /// Called when the user taps "Get Started" on the final page.
    let onLogin: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Edge-to-edge gradient base ──────────────────────────────
            LinearGradient(
                colors: [
                    AppColors.brandBackgroundDark,
                    AppColors.surface.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // ── Pages ───────────────────────────────────────────────────
            TabView(selection: $currentPage) {
                WelcomePage(onContinue: advance)
                    .tag(0)
                WhatIsAnchorPage(onContinue: advance)
                    .tag(1)
                HowItWorksPage(onContinue: advance)
                    .tag(2)
                WhyAnchorPage(onGetStarted: onLogin)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // ── Page indicator ──────────────────────────────────────────
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(
                            i == currentPage
                                ? AppColors.accent
                                : AppColors.textTertiary.opacity(0.35)
                        )
                        .frame(width: i == currentPage ? 22 : 6, height: 6)
                        .animation(AppMotion.standard, value: currentPage)
                }
            }
            .padding(.bottom, 52)
        }
        .ignoresSafeArea()
    }

    private func advance() {
        guard currentPage < 3 else { return }
        withAnimation(reduceMotion ? .none : AppMotion.standard) {
            currentPage += 1
        }
    }
}

// MARK: - Page 1 · Welcome to Anchor

private struct WelcomePage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false
    @State private var blob1: CGSize = .zero
    @State private var blob2: CGSize = .zero
    @State private var blob3: CGSize = .zero
    @State private var showTitle = false
    @State private var showButton = false

    let onContinue: () -> Void

    var body: some View {
        ZStack {
            if !reduceMotion { floatingBlobs }

            VStack(spacing: 0) {
                Spacer()

                // Title block
                VStack(spacing: 6) {
                    Text("Welcome to")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary.opacity(0.8))

                    Text("Anchor")
                        .font(.system(size: 68, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.textPrimary, AppColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .multilineTextAlignment(.center)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacing2)
                        .background(glassCapsule)
                        .shadow(color: AppColors.accent.opacity(0.4), radius: 20, x: 0, y: 8)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, Theme.spacing4)
                .padding(.bottom, 108)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if reduceMotion {
                showTitle = true; showButton = true
                return
            }

            // Blobs drift slowly and perpetually
            withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                blob1 = CGSize(width: 22, height: 14)
            }
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                blob2 = CGSize(width: -16, height: -22)
            }
            withAnimation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true)) {
                blob3 = CGSize(width: 18, height: -12)
            }

            withAnimation(AppMotion.gentleSpring.delay(0.12)) { showTitle = true }
            withAnimation(AppMotion.gentleSpring.delay(0.30)) { showButton = true }
        }
    }

    private var floatingBlobs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.accent.opacity(0.50), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: -80 + blob1.width, y: -200 + blob1.height)
                .blur(radius: 55)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.primary.opacity(0.38), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .offset(x: 120 + blob2.width, y: 60 + blob2.height)
                .blur(radius: 45)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.brandAccentSoft.opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .offset(x: -40 + blob3.width, y: 200 + blob3.height)
                .blur(radius: 38)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Page 2 · What is Anchor?

private struct WhatIsAnchorPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false
    @State private var showIllustration = false
    @State private var showText = false
    @State private var showButton = false
    @State private var iconPulse = false

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // ── Illustration ────────────────────────────────────────────
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.45), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 168, height: 168)
                    .scaleEffect(iconPulse ? 1.06 : 1.0)

                // Glass disc
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().fill(
                            LinearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.18),
                                    AppColors.primary.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .overlay(Circle().stroke(AppColors.accent.opacity(0.28), lineWidth: 1))
                    .frame(width: 116, height: 116)
                    .shadow(color: AppColors.accent.opacity(0.32), radius: 32, x: 0, y: 10)

                Image(systemName: "anchor")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.textPrimary, AppColors.accent.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(iconPulse ? 1.05 : 1.0)

                // Orbiting mini icons
                ForEach(
                    Array(zip(
                        ["lock.fill", "iphone", "app.badge.fill"],
                        [0, 1, 2]
                    )),
                    id: \.1
                ) { symbol, idx in
                    let angle = Double(idx) * 120.0 - 60.0
                    let r = Double.pi / 180 * angle
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.accent.opacity(0.75))
                        .padding(7)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle().stroke(AppColors.accent.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        .offset(x: CGFloat(cos(r)) * 84, y: CGFloat(sin(r)) * 84)
                }
            }
            .frame(height: 200)
            .opacity(showIllustration ? 1 : 0)
            .scaleEffect(showIllustration ? 1 : 0.82)

            Spacer().frame(height: Theme.spacing5)

            // ── Text ────────────────────────────────────────────────────
            VStack(spacing: Theme.spacing2) {
                Text("What is Anchor?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Anchor returns your time by blocking distracting apps until you complete your real-world goals.")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, Theme.spacing4)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 14)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing2)
                    .background(glassCapsule)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Theme.spacing4)
            .padding(.bottom, 108)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if reduceMotion {
                showIllustration = true; showText = true; showButton = true
                return
            }

            withAnimation(AppMotion.gentleSpring.delay(0.08)) { showIllustration = true }
            withAnimation(AppMotion.gentleSpring.delay(0.22)) { showText = true }
            withAnimation(AppMotion.gentleSpring.delay(0.36)) { showButton = true }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true).delay(0.5)) {
                iconPulse = true
            }
        }
    }
}

// MARK: - Page 3 · How it works

private struct HowItWorksPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false
    @State private var showHeader = false
    @State private var showRow = [false, false, false]

    let onContinue: () -> Void

    private let steps: [(icon: String, color: Color, title: String, detail: String)] = [
        (
            "checkmark.circle.fill",
            AppColors.success,
            "Set your daily goals",
            "Tell Anchor what you want to accomplish today."
        ),
        (
            "lock.app.dashed",
            AppColors.accent,
            "Anchor locks distracting apps",
            "Your selected apps are blocked until you've done the work."
        ),
        (
            "checkmark.seal.fill",
            AppColors.warning,
            "Complete goals to unlock your phone",
            "Check off your goals. Earn your screen time back."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("How it works")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : 10)
                .padding(.horizontal, Theme.spacing4)

            Spacer().frame(height: Theme.spacing5)

            VStack(spacing: Theme.spacing2) {
                ForEach(0..<3, id: \.self) { i in
                    stepRow(step: steps[i])
                        .opacity(showRow[i] ? 1 : 0)
                        .offset(y: showRow[i] ? 0 : 22)
                }
            }
            .padding(.horizontal, Theme.spacing3)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(AppTypography.button)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacing2)
                    .background(glassCapsule)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Theme.spacing4)
            .padding(.bottom, 108)
            .opacity(showRow[2] ? 1 : 0)
            .offset(y: showRow[2] ? 0 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if reduceMotion {
                showHeader = true
                showRow = [true, true, true]
                return
            }

            withAnimation(AppMotion.gentleSpring.delay(0.05)) { showHeader = true }
            withAnimation(AppMotion.gentleSpring.delay(0.20)) { showRow[0] = true }
            withAnimation(AppMotion.gentleSpring.delay(0.36)) { showRow[1] = true }
            withAnimation(AppMotion.gentleSpring.delay(0.52)) { showRow[2] = true }
        }
    }

    @ViewBuilder
    private func stepRow(step: (icon: String, color: Color, title: String, detail: String)) -> some View {
        HStack(spacing: Theme.spacing2) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                    .fill(step.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: step.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(step.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(AppTypography.sectionHeader)
                    .foregroundColor(AppColors.textPrimary)
                Text(step.detail)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Theme.spacing2)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                        .stroke(AppColors.border.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Page 4 · Why Anchor?

private struct WhyAnchorPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false
    @State private var showContent = false
    @State private var showButton = false

    let onGetStarted: () -> Void

    var body: some View {
        ZStack {
            if !reduceMotion {
                RadialGradient(
                    colors: [AppColors.accent.opacity(0.22), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 320
                )
                .ignoresSafeArea()
                .blur(radius: 64)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: Theme.spacing3) {
                    Text("Why Anchor?")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: Theme.spacing2) {
                        quoteFragment("We believe your time belongs to you.", primary: true)
                        quoteFragment("Not to algorithms. Not to infinite scrolls.", primary: false)
                        quoteFragment("Anchor helps you take it back.", primary: true)
                    }
                    .padding(.horizontal, Theme.spacing3)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 22)

                Spacer()

                // Get Started — solid accent CTA
                Button(action: onGetStarted) {
                    Text("Get Started")
                        .font(AppTypography.button)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacing2)
                        .background(
                            ZStack {
                                Capsule().fill(AppColors.accent)
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.14), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        )
                        .shadow(color: AppColors.accent.opacity(0.55), radius: 26, x: 0, y: 10)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, Theme.spacing4)
                .padding(.bottom, 108)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if reduceMotion {
                showContent = true; showButton = true
                return
            }
            withAnimation(AppMotion.gentleSpring.delay(0.10)) { showContent = true }
            withAnimation(AppMotion.gentleSpring.delay(0.40)) { showButton = true }
        }
    }

    private func quoteFragment(_ text: String, primary: Bool) -> some View {
        Text(text)
            .font(.system(size: 20, weight: primary ? .semibold : .regular, design: .rounded))
            .foregroundColor(primary ? AppColors.textPrimary : AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }
}

// MARK: - Shared helpers

/// Glass-morphism capsule background used on secondary Continue buttons.
private var glassCapsule: some View {
    ZStack {
        Capsule().fill(.ultraThinMaterial)
        Capsule().fill(
            LinearGradient(
                colors: [AppColors.accent.opacity(0.55), AppColors.accent.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        Capsule().stroke(AppColors.accent.opacity(0.38), lineWidth: 1)
    }
}

// MARK: - Preview

#Preview {
    OnboardingPagerView(onLogin: {})
}
