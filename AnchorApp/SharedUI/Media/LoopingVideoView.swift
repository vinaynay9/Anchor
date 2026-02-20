import SwiftUI
import AVKit

final class LoopingVideoPlayer: ObservableObject {
    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?

    init(resourceName: String, fileExtension: String) {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) {
            let item = AVPlayerItem(url: url)
            self.player = AVQueuePlayer(items: [item])
            self.looper = AVPlayerLooper(player: self.player, templateItem: item)
        } else {
            self.player = AVQueuePlayer()
        }
        self.player.isMuted = true
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
        player.seek(to: .zero)
    }
}

struct LoopingVideoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var videoPlayer: LoopingVideoPlayer
    private let aspectRatio: CGFloat
    private let cornerRadius: CGFloat

    @State private var isPlaying = false

    init(resourceName: String, fileExtension: String, aspectRatio: CGFloat = 16.0 / 9.0, cornerRadius: CGFloat = Theme.cornerRadiusLarge) {
        _videoPlayer = StateObject(wrappedValue: LoopingVideoPlayer(resourceName: resourceName, fileExtension: fileExtension))
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        ZStack {
            VideoPlayer(player: videoPlayer.player)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(AppColors.border, lineWidth: 1)
                )
                .shadow(color: AppColors.textPrimary.opacity(0.12), radius: 12, x: 0, y: 6)

            if reduceMotion {
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(AppColors.surface.opacity(0.9))
                        )
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            isPlaying = true
            videoPlayer.play()
        }
        .onDisappear {
            isPlaying = false
            videoPlayer.pause()
        }
    }

    private func togglePlay() {
        if isPlaying {
            isPlaying = false
            videoPlayer.pause()
        } else {
            isPlaying = true
            videoPlayer.play()
        }
    }
}
