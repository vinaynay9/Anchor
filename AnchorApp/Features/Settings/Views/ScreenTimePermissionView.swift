import SwiftUI
import FamilyControls

struct ScreenTimePermissionView: View {
    @State private var isAuthorized = false
    private let screenTimeService = ScreenTimeService.shared
    
    var body: some View {
        VStack(spacing: Theme.padding) {
            Text("Screen Time Permission")
                .font(AppTypography.title)
                .padding()
            
            Text("Anchor needs Screen Time permission to block apps during your focus sessions.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            
            if isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                    Text("Authorized")
                        .font(AppTypography.bodyBold)
                }
                .padding()
            } else {
                Button(action: {
                    Task {
                        do {
                            try await screenTimeService.requestAuthorization()
                            isAuthorized = screenTimeService.isAuthorized()
                        } catch {
                            // Handle error
                        }
                    }
                }) {
                    Text("Request Permission")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
        }
        .onAppear {
            isAuthorized = screenTimeService.isAuthorized()
        }
    }
}

