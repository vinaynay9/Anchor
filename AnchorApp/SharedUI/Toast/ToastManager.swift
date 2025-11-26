import SwiftUI
import Combine

/// Observable manager for toast notifications
/// Handles queueing, showing, and hiding toasts with animations
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published private(set) var currentToast: ToastModel?
    @Published private(set) var isShowing: Bool = false
    
    private var dismissTask: Task<Void, Never>?
    private var toastQueue: [ToastModel] = []
    
    private init() {}
    
    /// Show a success toast notification
    /// - Parameter message: The message to display
    func showSuccess(_ message: String, duration: Double = 2.5) {
        let toast = ToastModel(message: message, type: .success, duration: duration)
        showToast(toast)
    }
    
    /// Show an error toast notification
    /// - Parameter message: The message to display
    func showError(_ message: String, duration: Double = 2.5) {
        let toast = ToastModel(message: message, type: .error, duration: duration)
        showToast(toast)
    }
    
    /// Internal method to show a toast
    private func showToast(_ toast: ToastModel) {
        // Cancel any existing dismiss task
        dismissTask?.cancel()
        
        // If a toast is currently showing, queue this one
        if isShowing, let current = currentToast {
            toastQueue.append(toast)
            return
        }
        
        // Show the toast immediately
        currentToast = toast
        isShowing = true
        
        // Auto-dismiss after duration
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isShowing = false
            }
            
            // Wait for animation to complete before showing next toast
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            guard !Task.isCancelled else { return }
            
            currentToast = nil
            
            // Show next toast in queue if available
            if !toastQueue.isEmpty {
                let nextToast = toastQueue.removeFirst()
                showToast(nextToast)
            }
        }
    }
    
    /// Manually dismiss the current toast
    func dismiss() {
        dismissTask?.cancel()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = false
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            currentToast = nil
            
            // Show next toast in queue if available
            if !toastQueue.isEmpty {
                let nextToast = toastQueue.removeFirst()
                showToast(nextToast)
            }
        }
    }
}

