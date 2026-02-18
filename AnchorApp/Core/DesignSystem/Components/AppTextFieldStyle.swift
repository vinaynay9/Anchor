import SwiftUI

// MARK: - Text Field Style
struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .tint(AppColors.accent)
            .padding(.vertical, Theme.spacing2)
            .padding(.horizontal, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .fill(AppColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}

// MARK: - Search Field Style
struct SearchFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppTypography.body)
            .foregroundColor(AppColors.textPrimary)
            .tint(AppColors.accent)
            .padding(.vertical, Theme.spacing)
            .padding(.horizontal, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                    .fill(AppColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLarge)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
}
