import SwiftUI

// MARK: - Solid Card Component
struct SolidCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = Theme.spacing2, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.35), lineWidth: 1)
            )
    }
}

// MARK: - Glass Card Component (Legacy Compatibility)
struct GlassCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = Theme.spacing2, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        SolidCard(padding: padding) {
            content
        }
    }
}

// MARK: - Gradient Card Component (Legacy Compatibility)
struct GradientCard<Content: View>: View {
    let content: Content
    let padding: CGFloat

    init(padding: CGFloat = Theme.spacing2, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        SolidCard(padding: padding) {
            content
        }
    }
}
