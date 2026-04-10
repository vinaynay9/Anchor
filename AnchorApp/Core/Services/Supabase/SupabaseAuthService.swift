import Foundation
import Supabase

// MARK: - SupabaseAuthService
// Handles sign-in with Apple and Google via Supabase OpenID Connect.
//
// Usage (called from AppCoordinator.handleSocialAuthSuccess):
//   let userId = try await SupabaseAuthService.shared.signIn(
//       idToken: credential.identityToken,
//       provider: .apple,
//       rawNonce: credential.rawNonce
//   )

enum SupabaseAuthError: Error, LocalizedError {
    case notConfigured
    case invalidToken
    case signInFailed(String)
    case signOutFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:         return "Supabase is not yet configured. See SUPABASE_SETUP.md."
        case .invalidToken:          return "Identity token could not be read."
        case .signInFailed(let msg): return "Sign-in failed: \(msg)"
        case .signOutFailed(let msg): return "Sign-out failed: \(msg)"
        }
    }
}

// MARK: - Provider enum (mirrors SocialAuthCredential.Provider without coupling)
enum SupabaseOAuthProvider {
    case apple, google
}

final class SupabaseAuthService {
    static let shared = SupabaseAuthService()
    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Sign In with ID Token (Apple / Google)

    /// Exchange a social ID token with Supabase.
    /// - Parameters:
    ///   - idToken: JWT identity token from Apple or Google
    ///   - provider: .apple or .google
    ///   - rawNonce: The un-hashed nonce originally passed to the Apple Sign-In request.
    ///               Required for Apple; pass nil for Google.
    /// - Returns: Supabase user ID (UUID string) on success
    func signIn(idToken: String, provider: SupabaseOAuthProvider, rawNonce: String?) async throws -> String {
        let credentials = OpenIDConnectCredentials(
            provider: provider == .apple ? .apple : .google,
            idToken: idToken,
            nonce: rawNonce
        )
        let session = try await client.auth.signInWithIdToken(credentials: credentials)
        return session.user.id.uuidString
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Current Session

    /// Returns the authenticated Supabase user ID if a valid session exists, or nil.
    func currentUserId() async -> String? {
        try? await client.auth.session.user.id.uuidString
    }
}
