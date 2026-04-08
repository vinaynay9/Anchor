import Foundation
import AuthenticationServices
import CryptoKit
import UIKit
import GoogleSignIn

// MARK: - Social Auth View Model
// Handles the Apple and Google sign-in flows.
// Designed to work with SignInWithAppleButton (SwiftUI) for Apple,
// and GIDSignIn.sharedInstance for Google.
// All keys are read from Bundle.main.infoDictionary — zero code changes needed.

@MainActor
final class SocialAuthViewModel: ObservableObject {

    // MARK: - Published State
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Called on the main actor when a credential is successfully obtained.
    var onAuthSuccess: ((SocialAuthCredential) -> Void)?

    // MARK: - Apple Sign-In
    // Nonce is generated per-request and hashed before being embedded in the
    // Apple ID request. The raw nonce is verified server-side (Supabase) when
    // exchanging the identity token.
    private var currentNonce: String?

    /// Generates a cryptographic nonce, stores the raw value, and returns the
    /// SHA-256 hash to embed in the ASAuthorizationAppleIDRequest.
    /// Call this inside `SignInWithAppleButton`'s `onRequest` closure.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256Hash(nonce)
    }

    /// Handles the `Result<ASAuthorization, Error>` from `SignInWithAppleButton`'s
    /// `onCompletion` closure. Extracts identity token, auth code, and profile info.
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = false

        switch result {
        case .success(let auth):
            guard let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                LoggerService.shared.logWarning("Apple Sign-In: unexpected credential type", category: "Auth")
                errorMessage = "Sign in with Apple returned an unexpected credential."
                return
            }

            guard let tokenData = appleCredential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                LoggerService.shared.logWarning("Apple Sign-In: could not decode identity token", category: "Auth")
                errorMessage = "Sign in with Apple failed — could not read token."
                return
            }

            guard currentNonce != nil else {
                LoggerService.shared.logWarning("Apple Sign-In: nonce missing — possible replay attack", category: "Auth")
                errorMessage = "Sign in with Apple failed — security check failed."
                return
            }

            let authCode = appleCredential.authorizationCode
                .flatMap { String(data: $0, encoding: .utf8) }

            // Apple only provides name & email on the FIRST sign-in per app install.
            // Cache them locally on first receipt (handled by AppGroupStorage in the
            // profile setup step).
            let firstName = appleCredential.fullName?.givenName
            let lastName  = appleCredential.fullName?.familyName
            let email     = appleCredential.email

            LoggerService.shared.logInfo("Apple Sign-In: credential received (email=\(email != nil))", category: "Auth")

            let credential = SocialAuthCredential(
                provider: .apple,
                identityToken: identityToken,
                authorizationCode: authCode,
                email: email,
                firstName: firstName,
                lastName: lastName
            )
            onAuthSuccess?(credential)

        case .failure(let error):
            let nsError = error as NSError
            // ASAuthorizationError.canceled == 1001 — user dismissed; no error shown.
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                LoggerService.shared.logInfo("Apple Sign-In: cancelled by user", category: "Auth")
            } else {
                LoggerService.shared.logWarning("Apple Sign-In failed: \(error.localizedDescription)", category: "Auth")
                errorMessage = "Sign in with Apple failed. Please try again."
            }
        }
    }

    // MARK: - Google Sign-In

    /// Initiates Google Sign-In.
    /// Reads `GOOGLE_CLIENT_ID` from Info.plist — no code changes needed for keys.
    func signInWithGoogle() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
              !clientID.isEmpty,
              clientID != "REPLACE_ME" else {
            errorMessage = "Google Sign-In is not configured. See AUTH_SETUP.md."
            LoggerService.shared.logWarning("Google Sign-In: GOOGLE_CLIENT_ID not set in Info.plist", category: "Auth")
            return
        }

        // Resolve the presenting view controller from the foreground scene.
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.keyWindow?.rootViewController else {
            errorMessage = "Cannot present the sign-in screen."
            LoggerService.shared.logWarning("Google Sign-In: no foreground window found", category: "Auth")
            return
        }

        isLoading = true
        errorMessage = nil
        LoggerService.shared.logInfo("Google Sign-In: starting flow", category: "Auth")

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        Task {
            do {
                let result = try await withCheckedThrowingContinuation {
                    (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                    GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let signInResult {
                            continuation.resume(returning: signInResult)
                        } else {
                            continuation.resume(throwing: NSError(
                                domain: "GoogleSignIn",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "No result returned."]
                            ))
                        }
                    }
                }

                guard let idToken = result.user.idToken?.tokenString else {
                    isLoading = false
                    errorMessage = "Google Sign-In failed — no identity token returned."
                    LoggerService.shared.logWarning("Google Sign-In: idToken nil", category: "Auth")
                    return
                }

                LoggerService.shared.logInfo("Google Sign-In: credential received", category: "Auth")

                let credential = SocialAuthCredential(
                    provider: .google,
                    identityToken: idToken,
                    authorizationCode: nil,
                    email: result.user.profile?.email,
                    firstName: result.user.profile?.givenName,
                    lastName: result.user.profile?.familyName
                )
                isLoading = false
                onAuthSuccess?(credential)

            } catch let error as NSError {
                isLoading = false
                // GIDSignInError.canceled == -5 — user dismissed; no error shown.
                if error.code == -5 || error.localizedDescription.lowercased().contains("cancel") {
                    LoggerService.shared.logInfo("Google Sign-In: cancelled by user", category: "Auth")
                } else {
                    LoggerService.shared.logWarning("Google Sign-In failed: \(error.localizedDescription)", category: "Auth")
                    errorMessage = "Google Sign-In failed. Please try again."
                }
            }
        }
    }

    // MARK: - Cryptographic Helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256Hash(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
