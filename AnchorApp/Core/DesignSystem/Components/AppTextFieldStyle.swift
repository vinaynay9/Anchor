import SwiftUI

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.secondaryBackground)
            .cornerRadius(AppLayout.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .stroke(AppColors.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}

