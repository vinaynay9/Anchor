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
                                        AppColors.anchorPrimary.opacity(0.1),
                                        AppColors.anchorAccent.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.anchorLavender.opacity(0.3),
                                AppColors.anchorAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: AppColors.anchorPrimary.opacity(0.15),
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
                    .fill(AppColors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.anchorLavender.opacity(0.2),
                                AppColors.anchorAccent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
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
                                AppColors.secondaryBackground,
                                AppColors.secondaryBackground.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.anchorPrimary.opacity(0.3),
                                AppColors.anchorAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: AppColors.anchorAccent.opacity(0.2),
                radius: Theme.shadowRadius,
                x: 0,
                y: 4
            )
    }
}

