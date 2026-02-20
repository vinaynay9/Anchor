import Foundation
import SwiftUI
import Shared

// MARK: - URL Scheme Configuration Note
/// **Info.plist Configuration Required:**
/// To enable deep linking, the following URL scheme must be added to AnchorApp's Info.plist:
///
/// ```xml
/// <key>CFBundleURLTypes</key>
/// <array>
///     <dict>
///         <key>CFBundleURLSchemes</key>
///         <array>
///             <string>anchor</string>
///         </array>
///     </dict>
/// </array>
/// ```
///
/// Add alongside any other URL schemes your app uses.

// MARK: - Deep Link Types
/// Represents the different types of deep links that Anchor can handle
public enum DeepLink {
    case home
    case unlockRequest(id: String?)
    case session(id: String)
    case messagePartner
    case invite(inviterId: String, inviteCode: String)
    
    /// Parses a URL into a DeepLink enum
    /// - Parameter url: The URL to parse (e.g., "anchor://unlock-request/123")
    /// - Returns: A DeepLink if the URL is valid, nil otherwise
    static func parse(from url: URL) -> DeepLink? {
        if url.scheme == "anchor" {
            switch url.host {
            case "open":
                return .home
                
            case "unlock-request":
                // Extract ID from path if present: anchor://unlock-request/123
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                let id = pathComponents.first
                return .unlockRequest(id: id)
                
            case "session":
                // Extract session ID from path: anchor://session/123
                let pathComponents = url.pathComponents.filter { $0 != "/" }
                guard let sessionId = pathComponents.first else { return nil }
                return .session(id: sessionId)
                
            case "message-partner":
                return .messagePartner
                
            case "invite":
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let inviterId = components.queryItems?.first(where: { $0.name == "inviter" })?.value,
                   let inviteCode = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    return .invite(inviterId: inviterId, inviteCode: inviteCode)
                }
                return nil
                
            default:
                return nil
            }
        }
        
        // Support universal links like https://anchor.app/invite?code=...&inviter=...
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let host = components.host, host.contains("anchor."),
           components.path.contains("/invite"),
           let inviterId = components.queryItems?.first(where: { $0.name == "inviter" })?.value,
           let inviteCode = components.queryItems?.first(where: { $0.name == "code" })?.value {
            return .invite(inviterId: inviterId, inviteCode: inviteCode)
        }
        
        return nil
    }
}

// MARK: - Deep Link Handler Service
/// Service responsible for parsing deep links and coordinating navigation
/// Follows MVVM pattern by keeping navigation logic in a service layer
@MainActor
public class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()
    
    /// The current pending deep link to handle
    @Published var pendingDeepLink: DeepLink?
    
    private init() {}
    
    /// Handles an incoming URL by parsing it and storing it as a pending deep link
    /// The coordinator should observe pendingDeepLink and navigate accordingly
    /// - Parameter url: The URL to handle
    /// - Returns: true if the URL was recognized and handled, false otherwise
    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        guard let deepLink = DeepLink.parse(from: url) else {
            return false
        }
        
        // Store context in AppGroupStorage if needed (e.g., unlock request ID)
        // Context may already be set by shield extension when opening app
        if case .unlockRequest(let id) = deepLink, let requestId = id {
            AppGroupStorage.shared.setPendingDeepLinkContext(requestId: requestId)
        }
        if case .invite(let inviterId, let inviteCode) = deepLink {
            let attribution = InviteAttribution(inviterId: inviterId, inviteCode: inviteCode)
            AppGroupStorage.shared.setInviteAttribution(attribution)
        }
        
        pendingDeepLink = deepLink
        return true
    }
    
    /// Clears the pending deep link after it has been handled
    func clearPendingDeepLink() {
        pendingDeepLink = nil
    }
}
