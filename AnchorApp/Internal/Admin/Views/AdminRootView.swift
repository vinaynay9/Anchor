import SwiftUI

#if INTERNAL_TOOLS || DEBUG
struct AdminRootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if InternalTools.canAccessAdmin(user: authViewModel.currentUser) {
                List {
                    NavigationLink(destination: AnalyticsDashboardView()) {
                        Label("Analytics Dashboard", systemImage: "chart.xyaxis.line")
                    }
                }
                .navigationTitle("Admin")
            } else {
                Text("Internal tools unavailable.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .navigationTitle("Admin")
            }
        }
    }
}
#endif
