import SwiftUI

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let titleColor: Color?
    let action: (() -> Void)?
    let trailingContent: AnyView?
    let showChevron: Bool
    @State private var isPressed = false
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        titleColor: Color? = nil,
        action: (() -> Void)? = nil,
        trailingContent: AnyView? = nil,
        showChevron: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
        self.action = action
        self.trailingContent = trailingContent
        self.showChevron = showChevron
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                // Left icon
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .thin))
                    .foregroundColor(AppColors.anchorLavender)
                    .frame(width: 24, height: 24)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium, design: .default))
                        .foregroundColor(titleColor ?? AppColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Trailing content (chevron, toggle, etc.)
                if let trailing = trailingContent {
                    trailing
                } else if action != nil || showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, Theme.spacing2)
            .padding(.vertical, Theme.spacing2)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .fill(AppColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.anchorLavender.opacity(0.4),
                                        AppColors.anchorAccent.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: AppColors.anchorAccent.opacity(isPressed ? 0.3 : 0.1), radius: isPressed ? 8 : 4, x: 0, y: 0)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Convenience initializers
extension SettingsRowView {
    init(icon: String, title: String, titleColor: Color? = nil, action: @escaping () -> Void) {
        self.init(icon: icon, title: title, subtitle: nil, titleColor: titleColor, action: action, trailingContent: nil, showChevron: false)
    }
    
    init<T: View>(icon: String, title: String, titleColor: Color? = nil, trailing: T) {
        self.init(icon: icon, title: title, subtitle: nil, titleColor: titleColor, action: nil, trailingContent: AnyView(trailing), showChevron: false)
    }
    
    init(icon: String, title: String, titleColor: Color? = nil, isOn: Binding<Bool>) {
        self.init(
            icon: icon,
            title: title,
            subtitle: nil,
            titleColor: titleColor,
            action: nil,
            trailingContent: AnyView(
                Toggle("", isOn: isOn)
                    .tint(AppColors.anchorAccent)
                    .labelsHidden()
            ),
            showChevron: false
        )
    }
}

