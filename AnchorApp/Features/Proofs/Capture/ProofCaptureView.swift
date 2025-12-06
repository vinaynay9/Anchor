import SwiftUI
import UIKit

struct ProofCaptureView: View {
    let sessionId: String
    @StateObject private var viewModel = ProofCaptureViewModel()
    @State private var isCapturing = false
    @State private var showUploadView = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if showUploadView {
                ProofUploadView(viewModel: viewModel, sessionId: sessionId)
            } else {
                captureView
            }
        }
    }
    
    private var captureView: some View {
        ZStack {
            // Dark matte background
            AppColors.background
                .ignoresSafeArea()
            
            if let image = viewModel.capturedImage {
                // Show captured image with controls
                capturedImageView(image: image)
            } else {
                // Live camera preview
                cameraPreviewView
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
    }
    
    private var cameraPreviewView: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 12) {
                Text("Send proof to your friend")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Snap a quick photo to show what you're working on.")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Camera preview with glassmorphism
            ZStack {
                CameraView(
                    capturedImage: Binding(
                        get: { nil },
                        set: { newImage in
                            if let image = newImage {
                                viewModel.capturePhoto(from: image)
                            }
                        }
                    ),
                    isCapturing: $isCapturing
                )
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.5)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius))
                
                // Glassmorphism overlay
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .background(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [
                                AppColors.anchorPrimary.opacity(0.1),
                                AppColors.anchorAccent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.anchorAccent.opacity(0.6),
                                        AppColors.anchorLavender.opacity(0.4),
                                        AppColors.anchorAccent.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Bottom controls
            VStack(spacing: 24) {
                // Shutter button
                Button(action: {
                    HapticFeedback.soft()
                    isCapturing = true
                }) {
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.anchorAccent.opacity(0.3),
                                        AppColors.anchorLavender.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .blur(radius: 8)
                        
                        // Main button
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.anchorAccent,
                                        AppColors.anchorLavender
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        // Inner circle
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 40)
            .padding(.top, 24)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.background.opacity(0),
                        AppColors.background,
                        AppColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onChange(of: isCapturing) { capturing in
            if capturing {
                // Small delay to ensure camera is ready before capture
            }
        }
        .onChange(of: viewModel.capturedImage) { image in
            if image != nil {
                HapticFeedback.success()
            }
        }
    }
    
    private func capturedImageView(image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.anchorAccent.opacity(0.4),
                                    AppColors.anchorLavender.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .padding(8)
                )
            
            // Action buttons
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Retake button
                    Button(action: {
                        HapticFeedback.light()
                        viewModel.retakePhoto()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Retake")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.secondaryBackground)
                        .cornerRadius(AppLayout.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                                .stroke(AppColors.anchorLavender.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Use Photo button
                    Button(action: {
                        HapticFeedback.soft()
                        showUploadView = true
                    }) {
                        HStack(spacing: 8) {
                            Text("Use Photo")
                                .font(AppTypography.bodyBold)
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppColors.anchorAccent, AppColors.anchorLavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppLayout.cardCornerRadius)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.background.opacity(0),
                        AppColors.background,
                        AppColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
}

