import SwiftUI

/// Skeleton loading view that pulses to indicate loading state
struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.surface,
                        AppColors.surface.opacity(0.6),
                        AppColors.surface
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(isAnimating ? 0.5 : 0.8)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
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
            SkeletonView()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            
            // Text skeleton
            VStack(alignment: .leading, spacing: Theme.spacing) {
                SkeletonView()
                    .frame(height: 16)
                    .frame(width: 150)
                
                SkeletonView()
                    .frame(height: 12)
                    .frame(width: 100)
            }
            
            Spacer()
        }
        .padding(Theme.padding)
    }
}

/// Skeleton grid item for gallery views
struct SkeletonGridItem: View {
    var body: some View {
        SkeletonView()
            .aspectRatio(1, contentMode: .fit)
    }
}

/// Multiple skeleton rows for list loading states
struct SkeletonList: View {
    let count: Int
    
    init(count: Int = 3) {
        self.count = count
    }
    
    var body: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding(.horizontal, Theme.padding)
    }
}

/// Skeleton grid for gallery loading states
struct SkeletonGrid: View {
    let columns: Int
    let count: Int
    
    init(columns: Int = 2, count: Int = 6) {
        self.columns = columns
        self.count = count
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: Theme.spacing) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonGridItem()
            }
        }
        .padding(Theme.padding)
    }
}
