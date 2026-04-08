import SwiftUI
import AuthenticationServices

// MARK: - Social Auth View
// Full-screen sign-in screen with Sign in with Apple and Continue with Google.
// Keys are read from Bundle.main — see AUTH_SETUP.md for configuration.

struct SocialAuthView: View {
    @StateObject private var viewModel = SocialAuthViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Entry animation states
    @State private var showContent = false
    @State private var showButtons = false
    // Background blob drift offsets
    @State private var blob1: CGSize = .zero
    @State private var blob2: CGSize = .zero

    /// Forwarded to AppCoordinator which routes to profile setup.
    let onAuthSuccess: (SocialAuthCredential) -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()

                header
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                Spacer()

                buttonStack
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 24)

                errorBanner

                Spacer().frame(height: 56)
            }

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
        .onAppear { viewModel.onAuthSuccess = onAuthSuccess }
    }

    // MARK: - Sub-views

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.brandBackgroundDark, AppColors.surface.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !reduceMotion {
                // Two drifting blobs mirroring the onboarding aesthetic
                Circle()
                    .fill(RadialGradient(
                        colors: [AppColors.accent.opacity(0.38), .clear],
                        center: .center, startRadius: 0, endRadius: 210
                    ))
                    .frame(width: 420, height: 420)
                    .offset(x: -90 + blob1.width, y: -300 + blob1.height)
                    .blur(radius: 65)
                    .ignoresSafeArea()

                Circle()
                    .fill(RadialGradient(
                        colors: [AppColors.primary.opacity(0.26), .clear],
                        center: .center, startRadius: 0, endRadius: 160
                    ))
                    .frame(width: 320, height: 320)
                    .offset(x: 130 + blob2.width, y: 80 + blob2.height)
                    .blur(radius: 55)
                    .ignoresSafeArea()
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.spacing2) {
            // Anchor icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle().fill(
                            LinearGradient(
                                colors: [AppColors.accent.opacity(0.22), AppColors.primary.opacity(0.10)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    )
                    .overlay(Circle().stroke(AppColors.accent.opacity(0.30), lineWidth: 1))
                    .frame(width: 72, height: 72)
                    .shadow(color: AppColors.accent.opacity(0.30), radius: 22, x: 0, y: 8)

                Image(systemName: "anchor")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.textPrimary, AppColors.accent.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Spacer().frame(height: Theme.spacing2)

            Text("Sign In")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("Your time. Your goals. Your rules.")
                .font(AppTypography.helper)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing5)
        }
    }

    private var buttonStack: some View {
        VStack(spacing: Theme.spacing2) {
            // ── Sign in with Apple ──────────────────────────────────────
            // Apple requires using their provided button — do not modify the
            // SignInWithAppleButton rendering itself, only its frame.
            SignInWithAppleButton(.signIn, onRequest: { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = viewModel.prepareAppleSignIn()
            }, onCompletion: { result in
                viewModel.handleAppleSignInResult(result)
            })
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
            .disabled(viewModel.isLoading)

            // ── Continue with Google ────────────────────────────────────
            Button(action: { viewModel.signInWithGoogle() }) {
                HStack(spacing: 10) {
                    googleBadge
                    Text("Continue with Google")
                        .font(AppTypography.button)
                        .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.14))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMedium))
                .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, Theme.spacing4)
    }

    /// Stylised Google "G" badge — matches Google's brand colour spec.
    private var googleBadge: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)

            Text("G")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.52, blue: 0.96),  // Google Blue
                            Color(red: 0.92, green: 0.26, blue: 0.21)   // Google Red
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.error)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacing4)
                .padding(.top, Theme.spacing2)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            ProgressView()
                .tint(AppColors.textPrimary)
                .scaleEffect(1.4)
        }
    }

    // MARK: - Animation

    private func startAnimations() {
        if reduceMotion {
            showContent = true
            showButtons = true
            return
        }
        withAnimation(AppMotion.gentleSpring.delay(0.08)) { showContent = true }
        withAnimation(AppMotion.gentleSpring.delay(0.22)) { showButtons = true }
        withAnimation(.easeInOut(duration: 5.8).repeatForever(autoreverses: true)) {
            blob1 = CGSize(width: 20, height: 14)
        }
        withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true).delay(1.2)) {
            blob2 = CGSize(width: -16, height: -20)
        }
    }
}

// MARK: - Preview

#Preview {
    SocialAuthView(onAuthSuccess: { _ in })
}
