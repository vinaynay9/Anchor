import SwiftUI

struct AuthRootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.background)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .toolbar(.hidden, for: .navigationBar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
