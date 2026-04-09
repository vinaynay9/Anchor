import Foundation

// MARK: - SupabaseAuthService
// Handles sign-in with Apple and Google via Supabase OpenID Connect.
// Activated once supabase-swift SPM package is added.
//
// Usage (call from AppCoordinator.handleSocialAuthSuccess):
//   let session = try await SupabaseAuthService.shared.signIn(with: credential, nonce: rawNonce)

enum SupabaseAuthError: Error, LocalizedError {
    case notConfigured
    case invalidToken
    case signInFailed(String)
    case signOutFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:    return "Supabase is not yet configured. See SUPABASE_SETUP.md."
        case .invalidToken:     return "Identity token could not be read."
        case .signInFailed(let msg): return "Sign-in failed: \(msg)"
        case .signOutFailed(let msg): return "Sign-out failed: \(msg)"
        }
    }
}

// MARK: - Provider enum (mirrors SocialAuthCredential.Provider without import)
enum SupabaseOAuthProvider {
    case apple, google
}

final class SupabaseAuthService {
    static let shared = SupabaseAuthService()
    private init() {}

    // MARK: - Sign In with ID Token (Apple / Google)

    /// Exchange a social ID token with Supabase.
    /// - Parameters:
    ///   - idToken: JWT identity token from Apple or Google
    ///   - provider: .apple or .google
    ///   - rawNonce: The un-hashed nonce originally passed to Apple Sign-In request
    ///               (required for Apple; pass nil for Google)
    /// - Returns: Supabase user ID (UUID string) on success
    ///
    /// TODO: [Supabase] Uncomment after adding supabase-swift SPM package
    func signIn(idToken: String, provider: SupabaseOAuthProvider, rawNonce: String?) async throws -> String {
        guard SupabaseManager.shared.isConfigured else {
            throw SupabaseAuthError.notConfigured
        }

        // TODO: [Supabase] Activate after SPM package is added:
        //
        // import Supabase
        // let client = SupabaseManager.shared.client
        // let credentials = OpenIDConnectCredentials(
        //     provider: provider == .apple ? .apple : .google,
        //     idToken:  idToken,
        //     nonce:    rawNonce   // raw (unhashed) nonce for Apple; nil for Google
        // )
        // let session = try await client.auth.signInWithIdToken(credentials: credentials)
        // return session.user.id.uuidString

        throw SupabaseAuthError.notConfigured
    }

    // MARK: - Sign Out

    func signOut() async throws {
        guard SupabaseManager.shared.isConfigured else { return }

        // TODO: [Supabase] Activate after SPM package is added:
        // try await SupabaseManager.shared.client.auth.signOut()
    }

    // MARK: - Current Session

    /// Returns the authenticated Supabase user ID if a session exists, or nil.
    func currentUserId() async -> String? {
        guard SupabaseManager.shared.isConfigured else { return nil }

        // TODO: [Supabase] Activate after SPM package is added:
        // return try? await SupabaseManager.shared.client.auth.session.user.id.uuidString
        return nil
    }
}
