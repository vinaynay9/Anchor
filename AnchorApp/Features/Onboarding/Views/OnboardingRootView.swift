import SwiftUI

struct OnboardingRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = OnboardingFlowViewModel()

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch viewModel.stage {
            case .splash:
                FirstLaunchSplashView(onStart: {
                    viewModel.markSeen()
                })
                .transition(.opacity)

            case .pager:
                OnboardingPagerView(onLogin: {
                    viewModel.completeOnboarding()
                    onComplete()
                })
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(AppMotion.animation(AppMotion.standard, reduceMotion: reduceMotion), value: viewModel.stage)
    }
}
