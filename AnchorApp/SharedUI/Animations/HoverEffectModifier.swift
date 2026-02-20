import SwiftUI

struct AnchorHoverEffect: ViewModifier {
    var enabled: Bool = true
    @State private var isHovering = false

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 13.4, *) {
            content
                .hoverEffect(.highlight)
                .scaleEffect(isHovering && enabled ? 1.01 : 1.0)
                .onHover { hovering in
                    isHovering = hovering
                }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    func anchorHover(_ enabled: Bool = true) -> some View {
        modifier(AnchorHoverEffect(enabled: enabled))
    }
}
