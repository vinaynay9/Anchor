import SwiftUI

struct UsernameSetupView: View {
    @State private var username: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: Theme.padding) {
            Text("Choose a username")
                .font(AppTypography.title)
                .padding(.bottom, Theme.padding)
            
            TextField("Username", text: $username)
                .textFieldStyle(AppTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button(action: {
                // TODO: Save username
            }) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(username.isEmpty)
        }
        .padding(Theme.padding)
    }
}

