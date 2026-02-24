import SwiftUI

struct SignInOptionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var emailAuthViewModel = EmailAuthViewModel()
    @State private var mode: AuthMode = .signIn

    private enum AuthMode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }
    
    var body: some View {
        VStack(spacing: Theme.spacing * 2) {
            Spacer()
            
            Text("Anchor")
                .font(AppTypography.screenTitle)
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, Theme.padding * 2)
            
            Text("Lock apps. Set goals. Stay Anchored.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .padding(.bottom, Theme.padding * 3)
            
            Picker("Auth Mode", selection: $mode) {
                ForEach(AuthMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.padding)
            .onChange(of: mode) { _ in
                emailAuthViewModel.errorMessage = nil
                emailAuthViewModel.confirmPassword = ""
            }

            VStack(spacing: Theme.spacing2) {
                if mode == .signIn {
                    EmailSignInView(viewModel: emailAuthViewModel) { user in
                        authViewModel.handleAuthenticatedUser(user)
                    }
                } else {
                    EmailSignUpView(viewModel: emailAuthViewModel) { user in
                        authViewModel.handleAuthenticatedUser(user)
                    }
                }
            }
            .padding(.horizontal, Theme.padding)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Theme.padding)
        .background(AppColors.background)
        .ignoresSafeArea()
    }
}
