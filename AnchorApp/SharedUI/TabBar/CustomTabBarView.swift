import SwiftUI

struct CustomTabBarView: View {
    @Binding var selectedTab: TabItem
    @Namespace private var tabAnimation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabAnimation
                ) {
                    if reduceMotion {
                        selectedTab = tab
                    } else {
                        withAnimation(AppMotion.snappy) {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Ultra-dark blur overlay
                AppColors.surfaceElevated
                    .opacity(0.95)
                
                // Blur effect
                VisualEffectView(style: .systemUltraThinMaterial)
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
        )
        .shadow(color: AppColors.textPrimary.opacity(0.2), radius: 20, x: 0, y: -5)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 28,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 28
            )
            .stroke(
                LinearGradient(
                    colors: [
                        AppColors.accent.opacity(0.2),
                        AppColors.textTertiary.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
        )
    }
}

private struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Glow halo for selected tab
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.accent.opacity(0.4),
                                    AppColors.textTertiary.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 30
                            )
                        )
                        .blur(radius: 12)
                        .frame(width: 60, height: 60)
                        .matchedGeometryEffect(id: "selectedGlow", in: namespace)
                }
                
                // Icon
                Image(systemName: tab.iconName)
                    .font(AppTypography.sectionHeader)
                    .foregroundStyle(
                        isSelected
                            ? LinearGradient(
                                colors: [AppColors.accent, AppColors.textTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [AppColors.textSecondary, AppColors.textSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// Visual effect view for blur overlay
private struct VisualEffectView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
