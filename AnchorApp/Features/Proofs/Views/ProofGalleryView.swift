import SwiftUI

struct ProofGalleryView: View {
    let sessionId: UUID
    @StateObject private var viewModel = ProofViewModel()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.spacing) {
                ForEach(viewModel.proofs) { proof in
                    AsyncImage(url: proof.fileUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(AppColors.secondaryBackground)
                    }
                    .frame(height: 150)
                    .cornerRadius(Theme.cornerRadius)
                }
            }
            .padding(Theme.padding)
        }
        .navigationTitle("Proof Gallery")
        .onAppear {
            viewModel.loadProofs(sessionId: sessionId)
        }
    }
}

