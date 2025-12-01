import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyBold)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.anchorAccent)
            .cornerRadius(AppLayout.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyBold)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .cornerRadius(AppLayout.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.buttonCornerRadius)
                    .stroke(AppColors.anchorLavender.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.bodyBold)
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.error)
            .cornerRadius(AppLayout.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

