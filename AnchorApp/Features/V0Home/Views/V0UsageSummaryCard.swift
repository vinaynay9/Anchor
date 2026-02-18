import SwiftUI

struct V0UsageSummaryCard: View {
    private let screenTimeService = ScreenTimeService.shared

    var body: some View {
        SolidCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's usage")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                if screenTimeService.isAuthorized() {
                    Text("Usage summary will appear here once Screen Time data is available.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("Enable Screen Time to see today's totals.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
