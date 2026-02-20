import SwiftUI
import Shared

struct ProofGalleryView: View {
    let sessionId: String
    @StateObject private var viewModel = ProofViewModel()
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Error Banner
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, Theme.padding)
                    .padding(.top, Theme.spacing)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Content
                if viewModel.isLoading && viewModel.proofs.isEmpty {
                    // Initial loading with skeleton
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacing) {
                            ForEach(0..<6, id: \.self) { _ in
                                SkeletonGridItem()
                            }
                        }
                        .padding(Theme.padding)
                    }
                } else if viewModel.proofs.isEmpty {
                    // Empty state
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "No proofs yet",
                        message: "Proofs you capture during sessions will appear here",
                        actionTitle: nil,
                        action: nil
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Proof gallery
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacing) {
                            ForEach(viewModel.proofs) { proof in
                                proofImageCard(proof: proof)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(Theme.padding)
                    }
                }
            }
        }
        .navigationTitle("Proof Gallery")
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.proofs.count)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isLoading)
        .onAppear {
            viewModel.loadProofs(for: sessionId)
        }
    }
    
    private func proofImageCard(proof: Proof) -> some View {
        AsyncImage(url: proof.thumbnailUrl ?? proof.fileUrl) { phase in
            switch phase {
            case .empty:
                SkeletonGridItem()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .cornerRadius(AppLayout.cardCornerRadius)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.primary.opacity(0.3),
                                        AppColors.accent.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            case .failure:
                RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                    .fill(AppColors.secondaryBackground)
                    .frame(height: 150)
                    .overlay(
                        VStack(spacing: Theme.spacing) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(AppTypography.sectionHeader)
                                .foregroundColor(AppColors.error.opacity(0.7))
                            Text("Failed to load")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardCornerRadius)
                            .stroke(AppColors.error.opacity(0.2), lineWidth: 1)
                    )
            @unknown default:
                SkeletonGridItem()
            }
        }
    }
}

