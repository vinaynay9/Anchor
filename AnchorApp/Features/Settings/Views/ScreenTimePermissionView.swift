import SwiftUI

struct ScreenTimePermissionView: View {
    @StateObject private var viewModel = ScreenTimePermissionViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.spacing4) {
                    // Header
                    VStack(spacing: Theme.spacing2) {
                        ZStack {
                            Circle()
                                .fill(
                                    viewModel.status == .approved
                                        ? AppColors.success.opacity(0.2)
                                        : viewModel.status == .restricted
                                        ? AppColors.warning.opacity(0.2)
                                        : AppColors.anchorAccent.opacity(0.2)
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: viewModel.status == .approved ? "checkmark.shield.fill" : viewModel.status == .restricted ? "lock.shield.trianglebadge.exclamationmark.fill" : "lock.shield.fill")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(
                                    viewModel.status == .approved
                                        ? AppColors.success
                                        : viewModel.status == .restricted
                                        ? AppColors.warning
                                        : AppColors.anchorAccent
                                )
                        }
                        .padding(.top, Theme.spacing3)
                        
                        Text(statusTitle)
                            .font(AppTypography.largeTitle)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(statusDescription)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.spacing3)
                    }
                    
                    // Why section
                    VStack(alignment: .leading, spacing: Theme.spacing2) {
                        Text("Why Anchor Needs This")
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: Theme.spacing) {
                            ReasonBullet(text: "Identify distracting apps you use most")
                            ReasonBullet(text: "Block apps during your focus sessions")
                            ReasonBullet(text: "Enable friend-approved unlock requests")
                        }
                    }
                    .padding(Theme.spacing3)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(Theme.cornerRadiusMedium)
                    .padding(.horizontal, Theme.spacing3)
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(AppColors.warning)
                            Text(errorMessage)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(Theme.spacing2)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .padding(.horizontal, Theme.spacing3)
                    }
                    
                    // Action button
                    if viewModel.status == .approved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text("Screen Time Access Authorized")
                                .font(AppTypography.bodyBold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.spacing2)
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .padding(.horizontal, Theme.spacing3)
                    } else {
                        Button(action: {
                            if viewModel.status == .denied {
                                viewModel.openSettings()
                            } else if viewModel.status == .restricted {
                                // Restricted state - can't request, just show message
                                return
                            } else {
                                Task {
                                    await viewModel.requestPermission()
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
                        .disabled(viewModel.isRequesting || viewModel.status == .restricted)
                        .padding(.horizontal, Theme.spacing3)
                    }
                    
                    // Restricted state message
                    if viewModel.status == .restricted {
                        VStack(spacing: Theme.spacing) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppColors.warning)
                                Text("Parental Controls Active")
                                    .font(AppTypography.captionBold)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Text("Screen Time access is restricted by parental controls. Please contact your parent or guardian to enable access.")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(Theme.spacing2)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(Theme.cornerRadiusMedium)
                        .padding(.horizontal, Theme.spacing3)
                    }
                    
                    // Settings link for denied
                    if viewModel.status == .denied {
                        Button(action: {
                            viewModel.openSettings()
                        }) {
                            Text("Open Settings")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.anchorAccent)
                        }
                        .padding(.horizontal, Theme.spacing3)
                    }
                }
                .padding(.vertical, Theme.spacing3)
            }
        }
        .navigationTitle("Screen Time Permissions")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.checkStatus()
        }
    }
    
    private var statusTitle: String {
        switch viewModel.status {
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
        switch viewModel.status {
        case .approved:
            return "Anchor can now help you stay focused by blocking distracting apps."
        case .denied:
            return "To use Anchor's blocking features, please enable Screen Time access in Settings."
        case .restricted:
            return "Screen Time access is restricted by parental controls. Please contact your parent or guardian."
        case .notDetermined:
            return "Grant Anchor permission to manage your Screen Time so we can help you stay focused."
        }
    }
    
    private var buttonText: String {
        if viewModel.isRequesting {
            return "Requesting..."
        }
        
        switch viewModel.status {
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

struct ReasonBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacing) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.anchorAccent)
            
            Text(text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

