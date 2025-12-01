import SwiftUI

/// Skeleton loader view for placeholder content
struct SkeletonLoader: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.secondaryBackground,
                        AppColors.secondaryBackground.opacity(0.6),
                        AppColors.secondaryBackground
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AppColors.anchorAccent.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Skeleton row for list items
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: Theme.padding) {
            // Avatar skeleton
            SkeletonLoader(width: 56, height: 56, cornerRadius: 28)
            
            // Text skeletons
            VStack(alignment: .leading, spacing: Theme.spacing) {
                SkeletonLoader(width: 120, height: 16)
                SkeletonLoader(width: 80, height: 12)
            }
            
            Spacer()
        }
        .padding(Theme.padding)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppLayout.cardCornerRadius)
    }
}

/// Skeleton grid item for gallery views
struct SkeletonGridItem: View {
    var body: some View {
        SkeletonLoader(width: nil, height: 150, cornerRadius: AppLayout.cardCornerRadius)
    }
}

