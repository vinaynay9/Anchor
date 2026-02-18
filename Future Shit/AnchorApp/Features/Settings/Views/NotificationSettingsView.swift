import SwiftUI

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    private let notificationService = NotificationService.shared
    
    var body: some View {
        VStack(spacing: Theme.padding) {
            Text("Notification Settings")
                .font(AppTypography.title)
                .padding()
            
            Text("Enable notifications to receive unlock requests from your accountability partners.")
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

