import SwiftUI

struct AuthRootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if authViewModel.currentUser == nil {
                    SignInOptionsView()
                        .environmentObject(authViewModel)
                } else if authViewModel.needsUsernameSetup {
                    UsernameSetupView()
                        .environmentObject(authViewModel)
                } else {
                    // Main app placeholder - parent can replace this later
                    Text("Main app goes here")
                }
            }
        }
    }
}

