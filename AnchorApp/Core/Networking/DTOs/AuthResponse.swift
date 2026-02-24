import Foundation
import Shared

struct AuthResponse: Codable {
    let user: UserDTO
    let accessToken: String?
    let refreshToken: String?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case token
    }
}
