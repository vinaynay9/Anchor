import SwiftUI

struct OnboardingPageView<Content: View, Footer: View>: View {
    let title: String
    let bodyText: String?
    let iconName: String?
    let content: Content
    let footer: Footer

    init(
        title: String,
        bodyText: String?,
        iconName: String? = nil,
        @ViewBuilder content: () -> Content = { EmptyView() },
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.bodyText = bodyText
        self.iconName = iconName
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: Theme.spacing3) {
            Spacer()

            if let iconName {
                Image(systemName: iconName)
                    .font(AppTypography.screenTitle)
                    .foregroundColor(AppColors.accent)
                    .padding(.bottom, Theme.spacing)
            }

            Text(title)
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            content

            if let bodyText {
                Text(bodyText)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacing3)
            }

            footer
                .padding(.top, Theme.spacing2)
                .padding(.horizontal, Theme.spacing3)

            Spacer()
        }
        .padding(.horizontal, Theme.spacing3)
    }
}
