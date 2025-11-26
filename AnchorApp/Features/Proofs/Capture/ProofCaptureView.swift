import SwiftUI
import UIKit

struct ProofCaptureView: View {
    @StateObject private var viewModel = ProofCaptureViewModel()
    @State private var isCapturing = false
    @State private var showUploadView = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Group {
            if showUploadView {
                ProofUploadView(viewModel: viewModel)
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
            // Camera preview
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    // Gradient violet ring overlay
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.6),
                                    AppColors.accentLight.opacity(0.4),
                                    AppColors.accent.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .padding(8)
                )
            
            // Bottom controls
            VStack(spacing: 24) {
                // Shutter button
                Button(action: {
                    triggerHaptic(.medium)
                    isCapturing = true
                }) {
                    ZStack {
                        // Outer glow ring
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
                            .frame(width: 80, height: 80)
                            .blur(radius: 8)
                        
                        // Main button
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.accent,
                                        AppColors.accentLight
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
                // Small delay to ensure camera is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This will trigger the capture
                }
            }
        }
        .onChange(of: viewModel.capturedImage) { image in
            if image != nil {
                triggerHaptic(.success)
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
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.accent.opacity(0.4),
                                    AppColors.accentLight.opacity(0.3)
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
                        triggerHaptic(.light)
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
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppColors.accentLight.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Use Photo button
                    Button(action: {
                        triggerHaptic(.medium)
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
                                colors: [AppColors.accent, AppColors.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
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
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

