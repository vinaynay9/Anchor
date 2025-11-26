import SwiftUI

struct SettingsRowView: View {
    let icon: String
    let title: String
    let action: (() -> Void)?
    let trailingContent: AnyView?
    @State private var isPressed = false
    
    init(
        icon: String,
        title: String,
        action: (() -> Void)? = nil,
        trailingContent: AnyView? = nil
    ) {
        self.icon = icon
        self.title = title
        self.action = action
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                // Left icon
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .thin))
                    .foregroundColor(AppColors.accentLight)
                    .frame(width: 24, height: 24)
                
                // Title
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Trailing content (chevron, toggle, etc.)
                if let trailing = trailingContent {
                    trailing
                } else if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.accentLight.opacity(0.4),
                                        AppColors.accent.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: AppColors.accent.opacity(isPressed ? 0.3 : 0.1), radius: isPressed ? 8 : 4, x: 0, y: 0)
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
    init(icon: String, title: String, action: @escaping () -> Void) {
        self.init(icon: icon, title: title, action: action, trailingContent: nil)
    }
    
    init<T: View>(icon: String, title: String, trailing: T) {
        self.init(icon: icon, title: title, action: nil, trailingContent: AnyView(trailing))
    }
    
    init(icon: String, title: String, isOn: Binding<Bool>) {
        self.init(
            icon: icon,
            title: title,
            action: nil,
            trailingContent: AnyView(
                Toggle("", isOn: isOn)
                    .tint(AppColors.accent)
                    .labelsHidden()
            )
        )
    }
}

