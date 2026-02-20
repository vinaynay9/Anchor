import SwiftUI

struct UsernameSetupView: View {
    @State private var username: String = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: Theme.padding) {
            Text("Choose a username")
                .font(AppTypography.screenTitle)
                .padding(.bottom, Theme.padding)
            
            TextField("Username", text: $username)
                .textFieldStyle(AppTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            Button(action: {
                authViewModel.completeUsernameSetup(username)
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Continue")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(username.isEmpty || authViewModel.isLoading)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.top, Theme.spacing)
            }
        }
        .padding(Theme.padding)
    }
}

