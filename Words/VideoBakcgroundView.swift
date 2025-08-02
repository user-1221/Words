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
    @Published var errorMessage: String?
    
    private var looper: AVPlayerLooper?
    private var cancellables = Set<AnyCancellable>()
    private var playerObserver: Any?
    
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
        errorMessage = nil
        
        print("Loading video from URL: \(urlString)")
        
        // Create player item
        let playerItem = AVPlayerItem(url: url)
        
        // Create queue player for looping
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
                    print("Video ready to play")
                    self?.isLoading = false
                    self?.currentPlayer = queuePlayer
                    self?.currentBackgroundType = backgroundType
                    queuePlayer.play()
                case .failed:
                    print("Video failed to load: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    self?.isLoading = false
                    self?.hasError = true
                    self?.errorMessage = playerItem.error?.localizedDescription
                case .unknown:
                    print("Video status unknown")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Add periodic time observer to ensure playback
        playerObserver = queuePlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] _ in
            if queuePlayer.rate == 0 && queuePlayer.error == nil {
                queuePlayer.play()
            }
        }
    }
    
    func pauseVideo() {
        currentPlayer?.pause()
    }
    
    func resumeVideo() {
        currentPlayer?.play()
    }
    
    func cleanupCurrentPlayer() {
        if let observer = playerObserver {
            currentPlayer?.removeTimeObserver(observer)
        }
        currentPlayer?.pause()
        currentPlayer = nil
        looper = nil
        playerObserver = nil
    }
}

// MARK: - Persistent Video Background View
struct PersistentVideoBackgroundView: View {
    let backgroundType: BackgroundType
    @StateObject private var videoManager = VideoBackgroundManager.shared
    @State private var hasAttemptedLoad = false
    
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
                            .onDisappear {
                                videoManager.pauseVideo()
                            }
                    } else if videoManager.isLoading && !hasAttemptedLoad {
                        // Loading state with gradient background
                        ZStack {
                            backgroundType.gradient
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: backgroundType.textColor))
                                    .scaleEffect(1.5)
                                
                                Text("Loading video background...")
                                    .font(.system(size: 14))
                                    .foregroundColor(backgroundType.textColor.opacity(0.8))
                            }
                        }
                        .onAppear {
                            hasAttemptedLoad = true
                        }
                    } else if videoManager.hasError {
                        // Error state - show gradient fallback
                        backgroundType.gradient
                            .ignoresSafeArea()
                            .overlay(
                                VStack {
                                    Spacer()
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                        Text("Using fallback background")
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(backgroundType.textColor.opacity(0.6))
                                    .padding()
                                }
                            )
                    } else {
                        // Load new video or show gradient
                        backgroundType.gradient
                            .ignoresSafeArea()
                            .onAppear {
                                if !hasAttemptedLoad {
                                    videoManager.loadVideo(for: backgroundType)
                                    hasAttemptedLoad = true
                                }
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
        .onChange(of: backgroundType) { oldValue, newValue in
            hasAttemptedLoad = false
            if newValue.isVideo {
                videoManager.loadVideo(for: newValue)
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
        
        // Ensure player is playing
        player.play()
        
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
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
