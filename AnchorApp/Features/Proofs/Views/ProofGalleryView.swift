import SwiftUI
import Shared

struct ProofGalleryView: View {
    let sessionId: String
    @StateObject private var viewModel = ProofViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading proofs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else if viewModel.proofs.isEmpty {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No proofs yet")
                        .foregroundColor(.gray)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacing) {
                    ForEach(viewModel.proofs) { proof in
                        AsyncImage(url: proof.thumbnailUrl ?? proof.fileUrl) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(AppColors.secondaryBackground)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Rectangle()
                                    .fill(AppColors.secondaryBackground)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(AppColors.secondaryBackground)
                            }
                        }
                        .frame(height: 150)
                        .cornerRadius(AppLayout.cardCornerRadius)
                        .clipped()
                    }
                }
                .padding(Theme.padding)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("Proof Gallery")
        .onAppear {
            viewModel.loadProofs(for: sessionId)
        }
    }
}

