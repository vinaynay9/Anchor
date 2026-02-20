import SwiftUI

// MARK: - Glass Card Component
struct GlassCard<Content: View>: View {
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
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.primary.opacity(0.08),
                                        AppColors.accent.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .shadow(
                color: AppColors.primary.opacity(0.15),
                radius: Theme.shadowRadius,
                x: 0,
                y: 4
            )
    }
}

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
                    .fill(AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .shadow(
                color: AppColors.accent.opacity(0.15),
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

// MARK: - Gradient Card Component
struct GradientCard<Content: View>: View {
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
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.surface,
                                AppColors.surface.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.25), lineWidth: 1)
            )
            .shadow(
                color: AppColors.primary.opacity(0.2),
                radius: Theme.shadowRadius,
                x: 0,
                y: 4
            )
    }
}
