import SwiftUI
import Combine

/// Base protocol for all coordinators in the app
/// Coordinators manage navigation flow and view presentation
protocol Coordinator: ObservableObject {
    /// The navigation path managed by this coordinator
    var path: NavigationPath { get set }
    
    /// Start the coordinator's flow
    func start()
}

/// Protocol for coordinators that can present sheets
protocol SheetPresenting {
    var presentedSheet: SheetDestination? { get set }
}

/// Protocol for coordinators that can present full screen covers
protocol FullScreenCoverPresenting {
    var presentedFullScreenCover: FullScreenCoverDestination? { get set }
}

/// Enum for sheet destinations
enum SheetDestination: Identifiable, Hashable {
    case addFriend
    case createSession
    case selectApps
    
    var id: String {
        switch self {
        case .addFriend: return "addFriend"
        case .createSession: return "createSession"
        case .selectApps: return "selectApps"
        }
    }
}

/// Enum for full screen cover destinations
enum FullScreenCoverDestination: Identifiable, Hashable {
    case onboarding
    case proofCapture
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .proofCapture: return "proofCapture"
        }
    }
}

