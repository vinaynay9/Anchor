import SwiftUI

struct ScreenTimeOnboardingFlowView: View {
    @State private var currentStep: ScreenTimeOnboardingStep = .intro
    let onComplete: () -> Void
    
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
                        withAnimation(Theme.springAnimation) {
                            currentStep = .why
                        }
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .why:
                    ScreenTimeWhyView(onContinue: {
                        withAnimation(Theme.springAnimation) {
                            currentStep = .permission
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
            .animation(.easeOut(duration: 0.25), value: currentStep)
        }
    }
}

