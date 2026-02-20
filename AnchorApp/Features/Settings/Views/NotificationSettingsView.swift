import SwiftUI

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    private let notificationService = NotificationService.shared
    
    var body: some View {
        VStack(spacing: Theme.padding) {
            Text("Notification Settings")
                .font(AppTypography.screenTitle)
                .padding()
            
            Text("Enable notifications to stay Anchored and track goal completions.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                Task {
                    do {
                        try await notificationService.requestAuthorization()
                        notificationsEnabled = true
                    } catch {
                        // Handle error
                    }
                }
            }) {
                Text("Enable Notifications")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }
}

