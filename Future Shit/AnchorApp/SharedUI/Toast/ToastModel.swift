import Foundation

/// Model representing a toast notification
struct ToastModel: Identifiable, Equatable {
    let id: UUID
    let message: String
    let type: ToastType
    let duration: Double
    
    init(
        id: UUID = UUID(),
        message: String,
        type: ToastType,
        duration: Double = 2.5
    ) {
        self.id = id
        self.message = message
        self.type = type
        self.duration = duration
    }
}

/// Toast notification type variants
enum ToastType {
    case success
    case error
    case info
    case warning
}

