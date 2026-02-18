import Foundation

// MARK: - Supabase Client
// This is a wrapper around APIClient that adds Supabase-specific functionality
// For now, it's a placeholder that can be extended with real Supabase SDK integration

class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let apiClient = APIClient.shared
    
    // TODO: Integrate with Supabase Swift SDK when available
    // For now, use REST API via APIClient
    
    func setAuthToken(_ token: String) {
        // Store token in Keychain
        try? KeychainService.shared.save(token, forKey: AppConfig.UserDefaultsKeys.accessToken)
    }
    
    func clearAuthToken() {
        try? KeychainService.shared.delete(forKey: AppConfig.UserDefaultsKeys.accessToken)
    }
    
    var isAuthenticated: Bool {
        KeychainService.shared.exists(forKey: AppConfig.UserDefaultsKeys.accessToken)
    }
}

