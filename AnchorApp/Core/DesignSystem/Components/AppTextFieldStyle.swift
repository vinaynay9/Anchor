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
                    .fill(AppColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border.opacity(0.35), lineWidth: 1)
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
                    .fill(AppColors.surfaceElevated)
            )
    }
}
