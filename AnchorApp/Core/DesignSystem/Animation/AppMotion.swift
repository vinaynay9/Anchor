import SwiftUI

enum AppMotion {
    static let snappy = Animation.easeOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.28)
    static let gentleSpring = Animation.interpolatingSpring(stiffness: 220, damping: 26)

    static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

extension View {
    @ViewBuilder
    func motion<V: Equatable>(_ animation: Animation, reduceMotion: Bool, value: V) -> some View {
        if reduceMotion {
            self.animation(nil, value: value)
        } else {
            self.animation(animation, value: value)
        }
    }
}
