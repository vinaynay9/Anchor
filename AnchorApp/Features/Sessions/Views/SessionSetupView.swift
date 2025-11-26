import SwiftUI
import FamilyControls

struct SessionSetupView: View {
    @StateObject private var viewModel = SessionViewModel()
    @State private var selectedApps: [String] = []
    @State private var duration: TimeInterval?
    @State private var accountabilityPartnerId: UUID?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Apps to Block") {
                // TODO: Show FamilyActivityPicker
                Text("Select apps to block")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Section("Duration (Optional)") {
                // TODO: Add duration picker
                Text("Set session duration")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Section("Accountability Partner (Optional)") {
                // TODO: Show friend picker
                Text("Choose a friend")
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Button(action: {
                viewModel.startSession(
                    appsBlocked: selectedApps,
                    accountabilityPartnerId: accountabilityPartnerId,
                    duration: duration
                )
                dismiss()
            }) {
                Text("Start Session")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .navigationTitle("New Session")
    }
}

