import SwiftUI

struct OnboardingIconHeader<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            Spacer()
            content
        }
        .padding(.top, Theme.spacing3)
        .padding(.trailing, Theme.spacing3)
        .accessibilityHidden(true)
    }
}
