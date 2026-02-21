import Foundation
import CryptoKit

struct PKCE {
    let verifier: String
    let challenge: String
    let state: String

    static func generate() -> PKCE {
        let verifier = randomBase64URLString(length: 64)
        let challenge = sha256Base64URL(verifier)
        let state = randomBase64URLString(length: 32)
        return PKCE(verifier: verifier, challenge: challenge, state: state)
    }

    private static func randomBase64URLString(length: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func sha256Base64URL(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return Data(digest).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
