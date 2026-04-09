import Foundation

// MARK: - Social Auth Credential
// Encapsulates the result of a successful Apple or Google sign-in.
// Passed through the navigation stack to:
//  1. Pre-fill the profile setup form.
//  2. Exchange with the Supabase backend once the migration is complete.
struct SocialAuthCredential {

    enum Provider {
        case apple
        case google
    }

    /// Which OAuth provider produced this credential.
    let provider: Provider

    /// JWT identity token (Apple) or ID token (Google).
    /// Use this to authenticate with the backend (Supabase signInWithIdToken).
    let identityToken: String

    /// Server-side authorisation code — Apple only.
    /// Required for Supabase's server-side Apple token exchange.
    let authorizationCode: String?

    /// User's email address.
    /// Apple only provides this on the very first sign-in for a given app.
    let email: String?

    /// First / given name from the provider's profile.
    /// Apple only provides this on the very first sign-in.
    let firstName: String?

    /// Last / family name from the provider's profile.
    /// Apple only provides this on the very first sign-in.
    let lastName: String?

    /// Raw (unhashed) nonce used during Apple Sign-In request.
    /// Required by Supabase to verify the identity token.
    /// Pass nil for Google Sign-In.
    let rawNonce: String?
}
