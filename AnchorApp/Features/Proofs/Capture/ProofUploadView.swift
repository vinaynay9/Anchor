import SwiftUI

struct ProofUploadView: View {
    @ObservedObject var viewModel: ProofCaptureViewModel
    let sessionId: String
    @Environment(\.dismiss) var dismiss
    @State private var showSuccessAnimation = false
    
    var body: some View {
        ZStack {
            // Dark matte background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Image thumbnail
                if let image = viewModel.capturedImage {
                    imageThumbnail(image: image)
                        .scaleEffect(viewModel.uploadComplete ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.uploadComplete)
                }
                
                // Upload state section
                uploadStateSection
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(AppColors.textPrimary)
                        .font(AppTypography.body).fontWeight(.semibold)
                }
                .disabled(viewModel.isUploading)
            }
        }
        .onAppear {
            if !viewModel.isUploading && !viewModel.uploadComplete {
                viewModel.submitProof(sessionId: sessionId)
            }
        }
        .onChange(of: viewModel.uploadComplete) { complete in
            if complete {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showSuccessAnimation = true
                }
                // Auto-dismiss after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }
    
    private func imageThumbnail(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.accent.opacity(0.6),
                                AppColors.textTertiary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: AppColors.accent.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var uploadStateSection: some View {
        VStack(spacing: 24) {
            if viewModel.isUploading {
                // Uploading state
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        .scaleEffect(1.2)
                    
                    Text("Sending your proof…")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.secondaryBackground)
                                .frame(height: 6)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.accent, AppColors.textTertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.uploadProgress, height: 6)
                                .animation(.linear(duration: 0.1), value: viewModel.uploadProgress)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppLayout.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 1)
                )
            } else if viewModel.uploadComplete {
                // Success state
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppColors.success.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppTypography.screenTitle).fontWeight(.medium)
                            .foregroundColor(AppColors.success)
                            .scaleEffect(showSuccessAnimation ? 1.0 : 0.3)
                            .opacity(showSuccessAnimation ? 1.0 : 0.0)
                    }
                    
                    Text("Proof sent!")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textPrimary)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)
                        .offset(y: showSuccessAnimation ? 0 : 10)
                    
                    Text("Your friend will be able to see this proof when reviewing your request.")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)
                        .offset(y: showSuccessAnimation ? 0 : 10)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppLayout.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(AppColors.success.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(showSuccessAnimation ? 1.0 : 0.95)
                .opacity(showSuccessAnimation ? 1.0 : 0.0)
            } else if let errorMessage = viewModel.errorMessage {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(AppTypography.screenTitle).fontWeight(.medium)
                        .foregroundColor(AppColors.error)
                    
                    Text("Upload failed")
                        .font(AppTypography.sectionHeader)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(errorMessage)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        viewModel.submitProof(sessionId: sessionId)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(AppTypography.helper).fontWeight(.semibold)
                            Text("Try again")
                                .font(AppTypography.body)
                        }
                        .foregroundColor(AppColors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppColors.accent, AppColors.textTertiary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppLayout.cardCornerRadius)
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppLayout.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(AppColors.error.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

