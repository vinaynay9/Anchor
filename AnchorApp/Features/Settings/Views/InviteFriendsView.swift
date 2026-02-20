import SwiftUI
import Shared

struct InviteFriendsView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: Theme.spacing3) {
                Spacer()

                Text("Invite Friends")
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("Coming soon.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()
            }
            .padding(Theme.padding)
        }
        .navigationTitle("Invite Friends")
        .navigationBarTitleDisplayMode(.inline)
    }
}
