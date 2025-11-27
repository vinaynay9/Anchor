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
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
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
}

