import SwiftUI

struct UnlockRequestView: View {
    @StateObject private var viewModel = UnlockRequestViewModel()
    
    var body: some View {
        ZStack {
            // Purple gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.anchorPrimary,
                    AppColors.anchorAccent,
                    AppColors.anchorLavender
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
                                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                                    .fill(AppColors.anchorLavender.opacity(0.2))
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
                                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                                    .stroke(AppColors.anchorLavender.opacity(0.4), lineWidth: 1)
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
                                    .animation(Theme.springAnimation, value: viewModel.characterCount)
                            }
                        }
                        .padding(.bottom, Theme.padding)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.error)
                                .padding(.horizontal, Theme.spacing)
                                .padding(.vertical, Theme.spacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.error.opacity(0.1))
                                .cornerRadius(AppLayout.chipCornerRadius)
                                .padding(.bottom, Theme.spacing)
                        }
                        
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
                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                            .fill(AppColors.secondaryBackground.opacity(0.9))
                            .shadow(color: AppColors.anchorPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, Theme.padding)
                    
                    Spacer()
                        .frame(height: Theme.padding * 2)
                }
            }
        }
        .onChange(of: viewModel.isConfirmed) { isConfirmed in
            if isConfirmed {
                ToastManager.shared.show("Request Sent — Waiting for your partner to review")
            }
        }
    }
}

#Preview {
    UnlockRequestView()
}
