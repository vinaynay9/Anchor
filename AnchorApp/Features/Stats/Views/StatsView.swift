import SwiftUI

struct StatsView: View {
    var body: some View {
        ZStack {
            AppColors.brandBackgroundDark.ignoresSafeArea()

            VStack(spacing: Theme.spacing3) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(AppColors.accent.opacity(0.60))

                Text("Stats")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("Insights and streaks coming soon.")
                    .font(AppTypography.helper)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing4)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}
