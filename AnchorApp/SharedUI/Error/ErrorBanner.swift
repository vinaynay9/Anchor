import SwiftUI

/// Error banner view that displays error messages with dismiss functionality
struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: Theme.spacing) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.error)
                .font(AppTypography.body)
            
            Text(message)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: {
                    if reduceMotion {
                        onDismiss()
                    } else {
                        withAnimation(AppMotion.snappy) {
                            onDismiss()
                        }
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .font(AppTypography.body)
                }
            }
        }
        .padding(Theme.padding)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                .fill(AppColors.error.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, Theme.padding)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
