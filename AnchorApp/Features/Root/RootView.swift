import SwiftUI

enum AuthState {
    case signedOut
    case loading
    case signedIn
}

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    private var authState: AuthState {
        if authViewModel.isLoading {
            return .loading
        } else if authViewModel.currentUser != nil {
            return .signedIn
        } else {
            return .signedOut
        }
    }
    
    var body: some View {
        Group {
            switch authState {
            case .signedOut:
                AuthRootView()
                    .environmentObject(authViewModel)
            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .signedIn:
                MainTabView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

