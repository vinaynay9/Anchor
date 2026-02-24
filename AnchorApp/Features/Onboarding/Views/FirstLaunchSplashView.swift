import SwiftUI

struct FirstLaunchSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showTitle = false
    @State private var showButton = false

    let onStart: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            GeometryReader { proxy in
                VStack(spacing: Theme.spacing4) {
                    Spacer()

                    Text("Welcome to Anchor")
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.onboardingTitleText)
                        .opacity(showTitle ? 1 : 0)
                        .scaleEffect(showTitle ? 1.0 : 0.98)

                    Button(action: onStart) {
                        Text("Start Locking In")
                            .font(AppTypography.button)
                            .foregroundColor(AppColors.onboardingTitleText)
                            .padding(.vertical, Theme.spacing2)
                            .padding(.horizontal, Theme.spacing4)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(AppColors.accent.opacity(0.35), lineWidth: 1)
                                    )
                                    .overlay(
                                        LinearGradient(
                                            colors: [AppColors.accent.opacity(0.18), AppColors.accent.opacity(0.02)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .clipShape(Capsule())
                                    )
                            )
                            .shadow(color: AppColors.accent.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .opacity(showButton ? 1 : 0)

                    Spacer(minLength: max(16, proxy.safeAreaInsets.bottom + 12))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Theme.spacing4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if reduceMotion {
                showTitle = true
                showButton = true
            } else {
                animate(AppMotion.gentleSpring) {
                    showTitle = true
                }
                animate(AppMotion.standard, delay: 0.12) {
                    showButton = true
                }
            }
        }
    }

    private func animate(_ animation: Animation = AppMotion.gentleSpring, delay: Double = 0, _ changes: @escaping () -> Void) {
        if reduceMotion {
            changes()
        } else {
            withAnimation(animation.delay(delay)) {
                changes()
            }
        }
    }
}
