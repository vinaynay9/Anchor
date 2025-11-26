import SwiftUI

struct ProofUploadView: View {
    @ObservedObject var viewModel: ProofCaptureViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Dark matte background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Image thumbnail
                if let image = viewModel.capturedImage {
                    imageThumbnail(image: image)
                }
                
                // Upload progress section
                uploadProgressSection
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            
            // Upload complete banner
            if viewModel.uploadComplete {
                uploadCompleteBanner
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(AppColors.textPrimary)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .onAppear {
            viewModel.startUpload()
        }
    }
    
    private func imageThumbnail(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.accent.opacity(0.6),
                                AppColors.accentLight.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: AppColors.accent.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var uploadProgressSection: some View {
        VStack(spacing: 20) {
            if viewModel.isUploading {
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.secondaryBackground)
                                .frame(height: 8)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.accent, AppColors.accentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.uploadProgress, height: 8)
                                .animation(.linear(duration: 0.1), value: viewModel.uploadProgress)
                        }
                    }
                    .frame(height: 8)
                    
                    // Progress text
                    Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                // Placeholder for when not uploading
                Text("Preparing upload...")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var uploadCompleteBanner: some View {
        VStack(spacing: 16) {
            // Purple checkmark animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.accent.opacity(0.3),
                                AppColors.accentLight.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accent, AppColors.accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(viewModel.uploadComplete ? 1.0 : 0.5)
                    .opacity(viewModel.uploadComplete ? 1.0 : 0.0)
            }
            .scaleEffect(viewModel.uploadComplete ? 1.0 : 0.8)
            .opacity(viewModel.uploadComplete ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: viewModel.uploadComplete)
            
            // Success text
            Text("Upload Complete")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
                .opacity(viewModel.uploadComplete ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.4), value: viewModel.uploadComplete)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 40)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.6),
                                    AppColors.accentLight.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: AppColors.accent.opacity(0.3), radius: 30, x: 0, y: 15)
        .padding(.horizontal, 20)
        .onAppear {
            triggerHaptic(.success)
        }
    }
    
    private func triggerHaptic(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
}

