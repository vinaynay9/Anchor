import SwiftUI

/// Reusable breathing status dot animation
struct BreathingDotView: View {
    @State private var isBreathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Circle()
            .fill(AppColors.success)
            .frame(width: 8, height: 8)
            .scaleEffect(isBreathing ? 0.92 : 1.0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }
    }
}
