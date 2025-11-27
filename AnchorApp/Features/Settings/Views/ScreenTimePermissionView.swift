import SwiftUI

struct ScreenTimePermissionView: View {
    @StateObject private var viewModel = ScreenTimePermissionViewModel()
    
    var body: some View {
        VStack(spacing: Theme.padding) {
            Text("Screen Time Permission")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
                .padding()
            
            Text("Anchor needs Screen Time permission to block apps during your focus sessions.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            
            if viewModel.status == .approved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    Text("Authorized")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding()
            } else {
                Button(action: {
                    viewModel.requestPermission()
                }) {
                    Text("Enable Screen Time Access")
                        .font(AppTypography.bodyBold)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
        .padding(Theme.padding)
        .background(AppColors.anchorPrimaryDark)
        .cornerRadius(AppLayout.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .stroke(AppColors.anchorLavender, lineWidth: 1)
        )
    }
}

