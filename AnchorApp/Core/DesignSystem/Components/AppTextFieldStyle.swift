import SwiftUI

// MARK: - Text Field Style (Luxury Purple Theme)
struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(AppColors.secondaryBackground)
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
    }
}

// MARK: - Search Field Style
struct SearchFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .padding(.vertical, Theme.spacing)
            .padding(.horizontal, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                    .fill(AppColors.secondaryBackground)
            )
    }
}

