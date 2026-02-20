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
        ZStack(alignment: .topTrailing) {
            AppColors.background.ignoresSafeArea()

            Group {
                switch authState {
                case .signedOut:
                    AuthRootView()
                        .environmentObject(authViewModel)
                        .withGlobalToasts()
                case .loading:
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .withGlobalToasts()
                case .signedIn:
                    MainTabView()
                        .environmentObject(authViewModel)
                        .withGlobalToasts()
                }
            }

            #if INTERNAL_TOOLS || DEBUG
            if InternalTools.canAccessAdmin(user: authViewModel.currentUser) {
                internalToolsBadge
            }
            #endif
        }
    }

    private var internalToolsBadge: some View {
        Text("Internal Tools On")
            .font(AppTypography.caption)
            .foregroundColor(AppColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.secondaryBackground.opacity(0.95))
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(AppColors.textSecondary.opacity(0.4), lineWidth: 1)
            )
            .padding(.top, 10)
            .padding(.trailing, 12)
            .allowsHitTesting(false)
    }
}
