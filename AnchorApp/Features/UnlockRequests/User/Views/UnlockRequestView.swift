import SwiftUI

struct UnlockRequestView: View {
    @StateObject private var viewModel = UnlockRequestViewModel()
    @State private var showConfirmationToast = false
    
    var body: some View {
        ZStack {
            // Purple gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primary,
                    AppColors.accent,
                    AppColors.accentLight
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.padding * 2) {
                    Spacer()
                        .frame(height: Theme.padding * 2)
                    
                    // Content Card
                    VStack(alignment: .leading, spacing: Theme.padding) {
                        // Title
                        Text("Request Unlock")
                            .font(AppTypography.title)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, Theme.spacing)
                        
                        // Subtitle
                        Text("Tell your accountability partner why you need temporary access.")
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.bottom, Theme.padding)
                        
                        // Text Editor Container
                        VStack(alignment: .leading, spacing: Theme.spacing) {
                            ZStack(alignment: .topLeading) {
                                // Background
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .fill(AppColors.accentLight.opacity(0.2))
                                    .frame(minHeight: 150)
                                
                                // Text Editor
                                if viewModel.reason.isEmpty {
                                    Text("Enter your reason here...")
                                        .font(AppTypography.body)
                                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                                        .padding(.horizontal, Theme.padding)
                                        .padding(.vertical, Theme.padding + 4)
                                }
                                
                                TextEditor(text: $viewModel.reason)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .padding(Theme.padding)
                                    .background(Color.clear)
                                    .onChange(of: viewModel.reason) { newValue in
                                        // Limit to maxLength
                                        if newValue.count > 200 {
                                            viewModel.reason = String(newValue.prefix(200))
                                        }
                                    }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .stroke(AppColors.accentLight.opacity(0.4), lineWidth: 1)
                            )
                            
                            // Character Counter
                            HStack {
                                Spacer()
                                Text("\(viewModel.characterCount)/200")
                                    .font(AppTypography.caption)
                                    .foregroundColor(
                                        viewModel.characterCount > 200
                                            ? AppColors.error
                                            : AppColors.textSecondary
                                    )
                            }
                        }
                        .padding(.bottom, Theme.padding)
                        
                        // Send Request Button
                        Button(action: {
                            viewModel.sendRequest()
                        }) {
                            HStack {
                                if viewModel.isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                                } else {
                                    Text("Send Request")
                                        .font(AppTypography.bodyBold)
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!viewModel.canSend)
                        .opacity(viewModel.canSend ? 1.0 : 0.6)
                    }
                    .padding(Theme.padding * 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius * 1.5)
                            .fill(AppColors.secondaryBackground.opacity(0.9))
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, Theme.padding)
                    
                    Spacer()
                        .frame(height: Theme.padding * 2)
                }
            }
            
            // Confirmation Toast
            if showConfirmationToast {
                VStack {
                    Spacer()
                    
                    HStack(spacing: Theme.spacing) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                            .font(.title3)
                        
                        Text("Request Sent — Waiting for your partner to review")
                            .font(AppTypography.bodyBold)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(Theme.padding * 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .fill(AppColors.secondaryBackground)
                            .shadow(color: AppColors.accent.opacity(0.4), radius: 15, x: 0, y: 5)
                    )
                    .padding(.horizontal, Theme.padding * 2)
                    .padding(.bottom, Theme.padding * 3)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showConfirmationToast)
            }
        }
        .onChange(of: viewModel.isConfirmed) { isConfirmed in
            if isConfirmed {
                withAnimation {
                    showConfirmationToast = true
                }
                // Auto-dismiss toast after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showConfirmationToast = false
                    }
                }
            }
        }
    }
}

#Preview {
    UnlockRequestView()
}

