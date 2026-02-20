import Foundation
import AuthenticationServices
import UIKit

final class CognitoAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = CognitoAuthService()

    private let keychain = KeychainService.shared
    private let defaults = UserDefaults.standard
    private var authSession: ASWebAuthenticationSession?
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        return URLSession(configuration: config)
    }()

    private enum Keys {
        static let idToken = "cognitoIdToken"
        static let accessToken = "cognitoAccessToken"
        static let refreshToken = "cognitoRefreshToken"
        static let idTokenExpiry = "cognitoIdTokenExpiry"
    }

    private override init() {}

    var isSignedIn: Bool {
        guard let expiry = defaults.object(forKey: Keys.idTokenExpiry) as? TimeInterval else {
            return false
        }
        return Date().timeIntervalSince1970 < expiry
    }

    func signIn() async throws {
        let authURL = try buildAuthorizeURL()

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "anchor"
            ) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    continuation.resume(throwing: URLError(.badURL))
                    return
                }
                continuation.resume(returning: url)
            }
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = true
            authSession?.start()
        }

        let code = try extractCode(from: callbackURL)
        try await exchangeCodeForTokens(code: code)
    }

    func getValidIdToken() async -> String? {
        if let token = try? keychain.get(forKey: Keys.idToken),
           let expiry = defaults.object(forKey: Keys.idTokenExpiry) as? TimeInterval,
           Date().timeIntervalSince1970 < expiry {
            return token
        }

        guard let refreshToken = try? keychain.get(forKey: Keys.refreshToken) else {
            return nil
        }

        do {
            try await refreshTokens(refreshToken: refreshToken)
            return try? keychain.get(forKey: Keys.idToken)
        } catch {
            return nil
        }
    }

    func signOutLocal() {
        try? keychain.delete(forKey: Keys.idToken)
        try? keychain.delete(forKey: Keys.accessToken)
        try? keychain.delete(forKey: Keys.refreshToken)
        defaults.removeObject(forKey: Keys.idTokenExpiry)
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }

    // MARK: - Internals
    private func buildAuthorizeURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Secrets.cognitoDomain
        components.path = "/oauth2/authorize"
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Secrets.cognitoUserPoolClientId),
            URLQueryItem(name: "redirect_uri", value: Secrets.cognitoRedirectURI),
            URLQueryItem(name: "scope", value: "openid email")
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func extractCode(from url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              !code.isEmpty else {
            throw URLError(.badServerResponse)
        }
        return code
    }

    private func exchangeCodeForTokens(code: String) async throws {
        guard let tokenURL = URL(string: "https://\(Secrets.cognitoDomain)/oauth2/token") else {
            throw AnchorAPIError.configurationMissing
        }
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "client_id": Secrets.cognitoUserPoolClientId,
            "code": code,
            "redirect_uri": Secrets.cognitoRedirectURI
        ]
        request.httpBody = formEncoded(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        try storeTokens(from: tokenResponse)
    }

    private func refreshTokens(refreshToken: String) async throws {
        guard let tokenURL = URL(string: "https://\(Secrets.cognitoDomain)/oauth2/token") else {
            throw AnchorAPIError.configurationMissing
        }
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "client_id": Secrets.cognitoUserPoolClientId,
            "refresh_token": refreshToken
        ]
        request.httpBody = formEncoded(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        try storeTokens(from: tokenResponse, keepRefreshToken: true)
    }

    private func storeTokens(from response: CognitoTokenResponse, keepRefreshToken: Bool = false) throws {
        try keychain.save(response.id_token, forKey: Keys.idToken)
        try keychain.save(response.access_token, forKey: Keys.accessToken)
        if let refresh = response.refresh_token, !keepRefreshToken {
            try keychain.save(refresh, forKey: Keys.refreshToken)
        }
        if keepRefreshToken, let refresh = response.refresh_token {
            try keychain.save(refresh, forKey: Keys.refreshToken)
        }
        let expiry = Date().timeIntervalSince1970 + TimeInterval(response.expires_in)
        defaults.set(expiry, forKey: Keys.idTokenExpiry)
    }

    private func formEncoded(_ params: [String: String]) -> Data {
        let encoded = params
            .map { key, value in
                let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(k)=\(v)"
            }
            .joined(separator: "&")
        return Data(encoded.utf8)
    }
}

private struct CognitoTokenResponse: Codable {
    let access_token: String
    let id_token: String
    let refresh_token: String?
    let expires_in: Int
    let token_type: String
}
