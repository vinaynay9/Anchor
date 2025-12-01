import SwiftUI
import ManagedSettingsUI
import Shared

// MARK: - Shield View
// This view is shown when a user tries to open a blocked app

struct ShieldView: View {
    @StateObject private var viewModel = ShieldViewModel()
    @State private var isAppearing = false
    let context: ShieldConfigurationContext
    
    var body: some View {
        ZStack {
            ShieldColors.shieldBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: ShieldTheme.largeSpacing) {
                    Spacer(minLength: 40)
                    
                    // Icon with animation
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ShieldColors.primary, ShieldColors.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, ShieldTheme.spacing)
                        .scaleEffect(isAppearing ? 1.0 : 0.8)
                        .opacity(isAppearing ? 1.0 : 0.0)
                    
                    // Title
                    Text(viewModel.title)
                        .font(ShieldTypography.largeTitle)
                        .foregroundColor(ShieldColors.shieldText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ShieldTheme.padding)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .offset(y: isAppearing ? 0 : 10)
                    
                    // Subtitle
                    Text(viewModel.subtitle)
                        .font(ShieldTypography.title2)
                        .foregroundColor(ShieldColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ShieldTheme.padding)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .offset(y: isAppearing ? 0 : 10)
                    
                    // Remaining time badge
                    if let remainingTimeText = viewModel.remainingTimeText {
                        HStack(spacing: ShieldTheme.smallSpacing) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(remainingTimeText)
                                .font(ShieldTypography.title)
                        }
                        .foregroundColor(ShieldColors.primary)
                        .padding(.horizontal, ShieldTheme.padding)
                        .padding(.vertical, ShieldTheme.spacing)
                        .background(
                            Capsule()
                                .fill(ShieldColors.accentLight.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(ShieldColors.accentLight.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .scaleEffect(isAppearing ? 1.0 : 0.9)
                        .opacity(isAppearing ? 1.0 : 0.0)
                    }
                    
                    // Waiting for friend approval badge
                    if viewModel.isWaitingForFriendApproval {
                        HStack(spacing: ShieldTheme.smallSpacing) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Waiting for approval")
                                .font(ShieldTypography.caption)
                        }
                        .foregroundColor(ShieldColors.shieldText)
                        .padding(.horizontal, ShieldTheme.padding)
                        .padding(.vertical, ShieldTheme.spacing)
                        .background(
                            Capsule()
                                .fill(ShieldColors.accentLight.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(ShieldColors.accentLight.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .scaleEffect(isAppearing ? 1.0 : 0.9)
                        .opacity(isAppearing ? 1.0 : 0.0)
                    }
                    
                    // Explanatory message
                    VStack(spacing: ShieldTheme.smallSpacing) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ShieldColors.textSecondary)
                            Text(viewModel.explanationText)
                                .font(ShieldTypography.smallCaption)
                                .foregroundColor(ShieldColors.textTertiary)
                        }
                        .padding(.horizontal, ShieldTheme.padding)
                        .padding(.vertical, ShieldTheme.spacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                                .fill(ShieldColors.primaryDark.opacity(0.2))
                        )
                    }
                    .padding(.horizontal, ShieldTheme.padding)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .offset(y: isAppearing ? 0 : 10)
                    
                    Spacer(minLength: 20)
                    
                    // Action buttons
                    VStack(spacing: ShieldTheme.spacing) {
                        // Primary button - Request Unlock or Open Anchor
                        Button(action: {
                            if viewModel.isWaitingForFriendApproval {
                                viewModel.openAnchorApp()
                            } else {
                                viewModel.openUnlockRequest()
                            }
                        }) {
                            HStack(spacing: ShieldTheme.smallSpacing) {
                                Image(systemName: viewModel.isWaitingForFriendApproval ? "arrow.right.circle.fill" : "lock.open.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(viewModel.primaryButtonTitle)
                                    .font(ShieldTypography.bodyBold)
                            }
                            .foregroundColor(ShieldColors.shieldText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                                    .fill(ShieldColors.primaryButtonBackground)
                            )
                        }
                        .buttonStyle(ShieldButtonStyle())
                        
                        // Secondary button - Message Partner
                        Button(action: {
                            viewModel.openMessagePartner()
                        }) {
                            HStack(spacing: ShieldTheme.smallSpacing) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(viewModel.secondaryButtonTitle)
                                    .font(ShieldTypography.body)
                            }
                            .foregroundColor(ShieldColors.shieldText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                                    .fill(ShieldColors.secondaryButtonBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: ShieldTheme.cornerRadius)
                                            .stroke(ShieldColors.secondaryButtonBorder, lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(ShieldButtonStyle())
                    }
                    .padding(.horizontal, ShieldTheme.padding)
                    .padding(.bottom, ShieldTheme.padding * 2)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .offset(y: isAppearing ? 0 : 20)
                }
            }
        }
        .onAppear {
            viewModel.refresh()
            withAnimation(ShieldTheme.springAnimation) {
                isAppearing = true
            }
        }
    }
}

// MARK: - Shield Button Style
// Lightweight button style for extension performance
struct ShieldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(ShieldTheme.easeInOut, value: configuration.isPressed)
    }
}

