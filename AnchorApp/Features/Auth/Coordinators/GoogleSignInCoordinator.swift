import Foundation
import UIKit
import GoogleSignIn

private let kPreferredGooglePlistName = "GoogleService-Info"

enum GoogleSignInError: Error {
    case cancelled
    case noIDToken
    case signInFailed(Error)
    case noPresentingViewController
}

final class GoogleSignInCoordinator {
    static let shared = GoogleSignInCoordinator()
    
    private init() {}
    
    /// Signs in with Google and returns the ID token
    /// - Parameter presentingViewController: Optional view controller to present the sign-in flow from. If nil, will attempt to get root view controller.
    /// - Returns: The ID token string
    /// - Throws: GoogleSignInError if sign-in fails or is cancelled
    @MainActor
    func signIn(withPresenting presentingViewController: UIViewController? = nil) async throws -> String {
        let viewController = presentingViewController ?? getRootViewController()
        
        guard let viewController = viewController else {
            throw GoogleSignInError.noPresentingViewController
        }
        guard let clientID = getGoogleClientID() else {
            throw GoogleSignInError.signInFailed(NSError(
                domain: "GoogleSignIn",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Google Client ID not configured"]
            ))
        }
        
        // Configure GIDSignIn if not already configured
        if GIDSignIn.sharedInstance.configuration == nil {
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.noIDToken
            }
            
            return idToken
        } catch {
            // Check if user cancelled
            if let gidError = error as? GIDSignInError,
               gidError.code == .canceled {
                throw GoogleSignInError.cancelled
            }
            
            throw GoogleSignInError.signInFailed(error)
        }
    }
    
    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        // Return the topmost presented view controller, or root if none
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        
        return topViewController
    }
    
    private func getGoogleClientID() -> String? {
        // Prefer Secrets.googleClientID if available
        if !Secrets.googleClientID.isEmpty {
            return Secrets.googleClientID
        }
        // Try to get from Secrets.swift if it exists
        // Note: User must create Secrets.swift from Secrets.example.swift
        // and add their Google Client ID
        // Using runtime reflection to access Secrets.googleClientID
        if let secretsType = NSClassFromString("Secrets") as? NSObject.Type {
            if let clientID = secretsType.value(forKey: "googleClientID") as? String,
               !clientID.isEmpty,
               clientID != "your-google-client-id" {
                return clientID
            }
        }
        
        // Fallback: Try to get from Info.plist (preferred name first)
        let candidatePlistNames = [kPreferredGooglePlistName]
        for plistName in candidatePlistNames {
            if let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path) {
                if let actualClientID = plist["CLIENT_ID"] as? String, !actualClientID.isEmpty {
                    return actualClientID
                }
                // Some templates expose REVERSED_CLIENT_ID; ensure we map to CLIENT_ID above
                if let reversed = plist["REVERSED_CLIENT_ID"] as? String, !reversed.isEmpty,
                   let actualClientID = plist["CLIENT_ID"] as? String, !actualClientID.isEmpty {
                    return actualClientID
                }
            }
        }
        return nil
    }
}

