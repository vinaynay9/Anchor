import SwiftUI
import ManagedSettingsUI
import Shared

// MARK: - Shield View
// This view is shown when a user tries to open a blocked app

struct ShieldView: View {
    @StateObject private var viewModel = ShieldViewModel()
    let context: ShieldConfigurationContext
    
    var body: some View {
        ZStack {
            ShieldColors.shieldBackground
                .ignoresSafeArea()
            
            VStack(spacing: ShieldTheme.padding * 2) {
                Spacer()
                
                // Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ShieldColors.shieldText)
                    .padding(.bottom, ShieldTheme.padding)
                
                // Title
                Text(viewModel.title)
                    .font(ShieldTypography.largeTitle)
                    .foregroundColor(ShieldColors.shieldText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ShieldTheme.padding)
                
                // Subtitle
                Text(viewModel.subtitle)
                    .font(ShieldTypography.title2)
                    .foregroundColor(ShieldColors.shieldText.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ShieldTheme.padding)
                    .padding(.top, ShieldTheme.spacing)
                
                // Remaining time
                if let remainingTimeText = viewModel.remainingTimeText {
                    Text(remainingTimeText)
                        .font(ShieldTypography.largeTitle)
                        .foregroundColor(ShieldColors.primary)
                        .padding(.top, ShieldTheme.padding)
                }
                
                // Waiting for friend approval badge
                if viewModel.isWaitingForFriendApproval {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                        Text("Waiting for friend approval")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(ShieldColors.shieldText)
                    .padding(.horizontal, ShieldTheme.padding)
                    .padding(.vertical, ShieldTheme.spacing)
                    .background(ShieldColors.accentLight.opacity(0.15))
                    .cornerRadius(ShieldTheme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                            .stroke(ShieldColors.accentLight.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.top, ShieldTheme.padding)
                }
                
                Spacer()
                
                // Primary button
                Button(action: {
                    viewModel.openAnchorApp()
                }) {
                    Text(viewModel.primaryButtonTitle)
                        .font(ShieldTypography.bodyBold)
                        .foregroundColor(ShieldColors.shieldText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ShieldColors.primary)
                        .cornerRadius(ShieldTheme.cornerRadius)
                }
                .padding(.horizontal, ShieldTheme.padding)
                .padding(.bottom, ShieldTheme.padding * 2)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

