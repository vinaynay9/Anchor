import SwiftUI

/// Container view that positions and animates toast notifications at the top of the screen
struct ToastContainerView: View {
    @ObservedObject var toastManager: ToastManager
    
    var body: some View {
        ZStack(alignment: .top) {
            if let toast = toastManager.currentToast, toastManager.isShowing {
                ToastView(toast: toast)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.95)),
                            removal: .move(edge: .top)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.95))
                        )
                    )
                    .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: toastManager.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// Adds toast notification support to a view using environment object
    /// Requires `.environmentObject(ToastManager.shared)` to be set on a parent view
    /// - Returns: A view with toast notifications enabled
    func toastNotifications() -> some View {
        self.overlay(alignment: .top) {
            ToastContainerViewWithEnvironment()
        }
    }
    
    /// Adds toast notification support to a view with explicit manager
    /// - Parameter toastManager: The toast manager instance (typically `.shared`)
    /// - Returns: A view with toast notifications enabled
    func toastNotifications(toastManager: ToastManager) -> some View {
        self.overlay(alignment: .top) {
            ToastContainerView(toastManager: toastManager)
        }
    }
}

/// Internal container view that uses environment object
private struct ToastContainerViewWithEnvironment: View {
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        ToastContainerView(toastManager: toastManager)
    }
}

