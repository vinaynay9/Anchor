import SwiftUI

struct ScreenTimePermissionRequestView: View {
    @StateObject private var viewModel = ScreenTimeOnboardingViewModel()
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.spacing4) {
                Spacer()
                
                // Status icon
                ZStack {
                    Circle()
                        .fill(
                            viewModel.authorizationStatus == .approved
                                ? AppColors.success.opacity(0.2)
                                : viewModel.authorizationStatus == .restricted
                                ? AppColors.warning.opacity(0.2)
                                : AppColors.accent.opacity(0.2)
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: viewModel.authorizationStatus == .approved 
                          ? "checkmark.shield.fill" 
                          : viewModel.authorizationStatus == .restricted
                          ? "lock.shield.trianglebadge.exclamationmark.fill"
                          : "lock.shield.fill")
                        .font(AppTypography.screenTitle).fontWeight(.light)
                        .foregroundColor(
                            viewModel.authorizationStatus == .approved
                                ? AppColors.success
                                : viewModel.authorizationStatus == .restricted
                                ? AppColors.warning
                                : AppColors.accent
                        )
                }
                .padding(.bottom, Theme.spacing2)
                
                // Status text
                VStack(spacing: Theme.spacing2) {
                    Text(statusTitle)
                        .font(AppTypography.screenTitle)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(statusDescription)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.spacing3)
                }
                
                // Error message if denied or restricted
                if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                    VStack(spacing: Theme.spacing) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.warning)
                            Text(viewModel.authorizationStatus == .restricted ? "Parental Controls Active" : "Permission Denied")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        Text(viewModel.authorizationStatus == .restricted 
                             ? "Screen Time access is restricted by parental controls. Please contact your parent or guardian to enable access."
                             : "You can enable Screen Time access in Settings > Screen Time > Family Controls")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Theme.spacing2)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(Theme.cornerRadiusMedium)
                    .padding(.horizontal, Theme.spacing3)
                }
                
                Spacer()
                
                // Action button
                Button(action: {
                    if viewModel.authorizationStatus == .denied {
                        viewModel.openSettings()
                    } else if viewModel.authorizationStatus == .restricted {
                        // Restricted state - can't request, just show message
                        return
                    } else {
                        Task {
                            await viewModel.requestAuthorization()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.onPrimary))
                                .scaleEffect(0.8)
                        }
                        
                        Text(buttonText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isRequesting || viewModel.authorizationStatus == .approved || viewModel.authorizationStatus == .restricted)
                .padding(.horizontal, Theme.spacing3)
                
                // Continue button (only shown when authorized)
                if viewModel.authorizationStatus == .approved {
                    Button(action: onComplete) {
                        Text("Continue to App")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, Theme.spacing3)
                    .padding(.bottom, Theme.spacing3)
                } else {
                    Spacer()
                        .frame(height: Theme.spacing3)
                }
            }
        }
        .task {
            await viewModel.checkAuthorizationStatus()
        }
    }
    
    private var statusTitle: String {
        switch viewModel.authorizationStatus {
        case .approved:
            return "Screen Time Access Granted"
        case .denied:
            return "Screen Time Access Required"
        case .restricted:
            return "Screen Time Access Restricted"
        case .notDetermined:
            return "Enable Screen Time Access"
        }
    }
    
    private var statusDescription: String {
        switch viewModel.authorizationStatus {
        case .approved:
            return "You're all set! Anchor can now help you stay focused."
        case .denied:
            return "To use Anchor's blocking features, please enable Screen Time access in Settings."
        case .restricted:
            return "Screen Time access is restricted by parental controls. Please contact your parent or guardian."
        case .notDetermined:
            return "Tap the button below to grant Anchor permission to manage your Screen Time."
        }
    }
    
    private var buttonText: String {
        if viewModel.isRequesting {
            return "Requesting..."
        }
        
        switch viewModel.authorizationStatus {
        case .approved:
            return "Authorized"
        case .denied:
            return "Open Settings"
        case .restricted:
            return "Contact Parent/Guardian"
        case .notDetermined:
            return "Enable Screen Time Access"
        }
    }
}

