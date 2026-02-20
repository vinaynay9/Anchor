import SwiftUI

struct ScreenTimeOnboardingFlowView: View {
    @State private var currentStep: ScreenTimeOnboardingStep = .intro
    let onComplete: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    enum ScreenTimeOnboardingStep {
        case intro
        case why
        case permission
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            Group {
                switch currentStep {
                case .intro:
                    ScreenTimeIntroView(onContinue: {
                        if reduceMotion {
                            currentStep = .why
                        } else {
                            withAnimation(AppMotion.gentleSpring) {
                                currentStep = .why
                            }
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .why:
                    ScreenTimeWhyView(onContinue: {
                        if reduceMotion {
                            currentStep = .permission
                        } else {
                            withAnimation(AppMotion.gentleSpring) {
                                currentStep = .permission
                            }
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .permission:
                    ScreenTimePermissionRequestView(onComplete: onComplete)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .animation(AppMotion.animation(AppMotion.standard, reduceMotion: reduceMotion), value: currentStep)
        }
    }
}
