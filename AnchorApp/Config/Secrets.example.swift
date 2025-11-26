import Foundation

// MARK: - Example Secrets Structure
// Copy this file to Secrets.swift and fill in your actual values
// Add Secrets.swift to .gitignore

struct Secrets {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-anon-key"
    static let supabaseServiceRoleKey = "your-service-role-key"
    
    // Google Sign-In
    static let googleClientID = "your-google-client-id"
    
    // APNs (if needed for direct configuration)
    static let apnsKeyID = "your-apns-key-id"
    static let apnsTeamID = "your-apns-team-id"
}

