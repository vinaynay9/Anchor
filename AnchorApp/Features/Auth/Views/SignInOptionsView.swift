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
                    authViewModel.signInWithApple()
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "applelogo")
                        }
                        Text("Continue with Apple")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(authViewModel.isLoading)
                
                Button(action: {
                    authViewModel.signInWithGoogle()
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                        } else {
                            Image(systemName: "globe")
                        }
                        Text("Continue with Google")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(authViewModel.isLoading)
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

