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
        // Store token in UserDefaults or Keychain
        UserDefaults.standard.set(token, forKey: AppConfig.UserDefaultsKeys.accessToken)
    }
    
    func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: AppConfig.UserDefaultsKeys.accessToken)
    }
    
    var isAuthenticated: Bool {
        UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKeys.accessToken) != nil
    }
}

