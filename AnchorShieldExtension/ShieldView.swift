import SwiftUI
import Shared

struct ShieldView: View {
    @StateObject private var viewModel = ShieldViewModel()
    @Environment(\.openURL) private var openURLAction

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.background, AppColors.background2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                VStack(spacing: 8) {
                    Text(viewModel.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text(viewModel.subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                if let progress = viewModel.progressText {
                    Text(progress)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Button("Open Anchor") {
                    if let url = URL(string: "anchor://open") {
                        openURLAction(url)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.primary))
            }
            .padding()
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}
