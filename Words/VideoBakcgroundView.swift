import SwiftUI
import AVKit
import Combine

// MARK: - Video Manager Singleton
class VideoBackgroundManager: ObservableObject {
    static let shared = VideoBackgroundManager()
    
    @Published var currentPlayer: AVPlayer?
    @Published var currentBackgroundType: BackgroundType?
    @Published var isLoading = false
    @Published var hasError = false
    
    private var looper: AVPlayerLooper?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func loadVideo(for backgroundType: BackgroundType) {
        // Don't reload if it's the same video
        if currentBackgroundType == backgroundType, currentPlayer != nil {
            return
        }
        
        // Clean up previous player
        cleanupCurrentPlayer()
        
        guard backgroundType.isVideo,
              let urlString = backgroundType.videoURL,
              let url = URL(string: urlString) else {
            currentBackgroundType = backgroundType
            return
        }
        
        isLoading = true
        hasError = false
        
        // Create player item
        let playerItem = AVPlayerItem(url: url)

        // Create queue player
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.allowsExternalPlayback = false
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

        // Set up looping
        looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // Monitor loading status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.currentPlayer = queuePlayer
                    self?.currentBackgroundType = backgroundType
                    queuePlayer.play()
                case .failed:
                    self?.isLoading = false
                    self?.hasError = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func pauseVideo() {
        currentPlayer?.pause()
    }
    
    func resumeVideo() {
        currentPlayer?.play()
    }
    
    func cleanupCurrentPlayer() {
        currentPlayer?.pause()
        currentPlayer = nil
        looper = nil
    }
}

// MARK: - Persistent Video Background View
struct PersistentVideoBackgroundView: View {
    let backgroundType: BackgroundType
    @StateObject private var videoManager = VideoBackgroundManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if backgroundType.isVideo {
                    if let player = videoManager.currentPlayer,
                       videoManager.currentBackgroundType == backgroundType {
                        // Use existing player
                        VideoPlayerView(player: player, geometry: geometry)
                            .ignoresSafeArea()
                            .onAppear {
                                videoManager.resumeVideo()
                            }
                    } else if videoManager.isLoading {
                        // Loading state
                        ZStack {
                            backgroundType.gradient
                                .ignoresSafeArea()
                            
                            VStack {
                                ProgressView("Loading background...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: backgroundType.textColor))
                                    .foregroundColor(backgroundType.textColor)
                                    .scaleEffect(1.2)
                            }
                        }
                    } else {
                        // Load new video or show gradient
                        backgroundType.gradient
                            .ignoresSafeArea()
                            .onAppear {
                                videoManager.loadVideo(for: backgroundType)
                            }
                    }
                } else {
                    // Regular gradient background
                    backgroundType.gradient
                        .ignoresSafeArea()
                        .onAppear {
                            // Clear video if switching to gradient
                            if videoManager.currentBackgroundType?.isVideo == true {
                                videoManager.cleanupCurrentPlayer()
                            }
                            videoManager.currentBackgroundType = backgroundType
                        }
                }
            }
        }
    }
}

// MARK: - Custom Video Player View with Aspect Fill
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let geometry: GeometryProxy
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = CGRect(origin: .zero, size: geometry.size)
        
        view.layer.addSublayer(playerLayer)
        view.playerLayer = playerLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerView = uiView as? PlayerUIView {
            playerView.playerLayer?.frame = CGRect(origin: .zero, size: geometry.size)
        }
    }
    
    class PlayerUIView: UIView {
        var playerLayer: AVPlayerLayer?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }
    }
}

// MARK: - Scene Phase Handler
struct VideoBackgroundSceneModifier: ViewModifier {
    @Environment(\.scenePhase) var scenePhase
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) {
                switch scenePhase {
                case .active:
                    VideoBackgroundManager.shared.resumeVideo()
                case .inactive, .background:
                    VideoBackgroundManager.shared.pauseVideo()
                @unknown default:
                    break
                }
            }
    }
}

extension View {
    func handleVideoBackgroundLifecycle() -> some View {
        modifier(VideoBackgroundSceneModifier())
    }
}
