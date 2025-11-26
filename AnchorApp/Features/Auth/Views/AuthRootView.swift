import SwiftUI

struct AuthRootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            SignInOptionsView()
        }
    }
}

