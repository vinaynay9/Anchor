import Foundation
import AuthenticationServices
import UIKit

enum AppleSignInError: Error {
    case cancelled
    case failed(Error)
    case invalidResponse
    case invalidToken
}

protocol AppleSignInCoordinatorProtocol {
    func performSignIn() async throws -> String
}

final class AppleSignInCoordinator: NSObject, AppleSignInCoordinatorProtocol {
    private var continuation: CheckedContinuation<String, Error>?
    
    func performSignIn() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            
            authorizationController.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AppleSignInError.invalidToken)
            continuation = nil
            return
        }
        
        continuation?.resume(returning: identityToken)
        continuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation?.resume(throwing: AppleSignInError.cancelled)
            default:
                continuation?.resume(throwing: AppleSignInError.failed(error))
            }
        } else {
            continuation?.resume(throwing: AppleSignInError.failed(error))
        }
        continuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window from connected scenes (iOS 13+)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // Fallback: get any foreground window
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first {
            return window
        }
        
        // Last resort: create a temporary window (shouldn't happen in normal flow)
        return UIWindow(frame: UIScreen.main.bounds)
    }
}

