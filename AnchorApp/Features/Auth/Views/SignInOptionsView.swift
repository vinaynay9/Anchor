import SwiftUI

struct SignInOptionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: Theme.spacing * 2) {
            Spacer()
            
            Text("Anchor")
                .font(AppTypography.largeTitle)
                .padding(.bottom, Theme.padding * 2)
            
            Text("Stay accountable. Stay focused.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, Theme.padding * 3)
            
            VStack(spacing: Theme.spacing) {
                Button(action: {
                    authViewModel.signIn(with: .apple)
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Continue with Apple")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: {
                    authViewModel.signIn(with: .google)
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Continue with Google")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Theme.padding)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.top, Theme.spacing)
            }
            
            Spacer()
        }
    }
}

