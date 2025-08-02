import SwiftUI
import AVKit
import Combine

// MARK: - Video Background Manager
class VideoBackgroundManager: ObservableObject {
    static let shared = VideoBackgroundManager()
    
    @Published var currentPlayer: AVQueuePlayer?
    @Published var currentBackgroundType: BackgroundType?
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage: String?
    
    private var looper: AVPlayerLooper?
    private var cancellables = Set<AnyCancellable>()
    private var playerTimeObserver: Any?
    private weak var observerPlayer: AVQueuePlayer? // 👈 これを追加
    private var currentPlayerItem: AVPlayerItem?
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Load Video
    func loadVideo(for backgroundType: BackgroundType) {
        if currentBackgroundType == backgroundType,
           currentPlayer != nil,
           currentPlayer?.error == nil {
            currentPlayer?.play()
            return
        }
        
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

        // Dispatch async to prepare video asset
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let queuePlayer = AVQueuePlayer()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.currentPlayerItem = playerItem
                self.currentPlayer = queuePlayer
                
                // Setup Looper
                self.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

                // Setup Observers
                self.setupPlayerObservers(for: playerItem, player: queuePlayer, backgroundType: backgroundType)
                
                // Assign observer player
                self.observerPlayer = queuePlayer
                
                // Start playback
                queuePlayer.play()
            }
        }
    }

    
    // MARK: - Player Observers
    private func setupPlayerObservers(for playerItem: AVPlayerItem, player: AVQueuePlayer, backgroundType: BackgroundType) {
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.currentPlayer = player
                    self?.currentBackgroundType = backgroundType
                    player.play()
                case .failed:
                    self?.handleError(playerItem.error, backgroundType: backgroundType)
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        
        playerTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self, weak player] _ in
            guard let player = player else { return }
            if player.rate == 0 && player.error == nil && playerItem.status == .readyToPlay {
                player.play()
            }
        }
        
        observerPlayer = player // 👈 このプレイヤーに observer を追加したことを記録
        
        player.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .failed {
                    self?.handleError(player.error, backgroundType: backgroundType)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error?, backgroundType: BackgroundType) {
        isLoading = false
        hasError = true
        errorMessage = error?.localizedDescription ?? "Failed to load video"
        
        if let fallbackURL = URL(string: VideoConfig.fallbackVideoURL()) {
            let fallbackItem = AVPlayerItem(url: fallbackURL)
            let fallbackPlayer = AVQueuePlayer(playerItem: fallbackItem)
            fallbackPlayer.isMuted = true
            
            currentPlayer = fallbackPlayer
            currentBackgroundType = backgroundType
            fallbackPlayer.play()
        }
    }
    
    // MARK: - Playback Control
    func pauseVideo() {
        currentPlayer?.pause()
    }
    
    func resumeVideo() {
        if let player = currentPlayer,
           player.timeControlStatus != .playing {
            player.play()
        }
    }
    
    // MARK: - Cleanup
    func cleanupCurrentPlayer() {
        if let observer = playerTimeObserver,
           let player = observerPlayer { // 👈 observer を追加したプレイヤーで remove
            player.removeTimeObserver(observer)
        }
        playerTimeObserver = nil
        observerPlayer = nil
        
        currentPlayer?.pause()
        currentPlayer?.replaceCurrentItem(with: nil)
        currentPlayer = nil
        currentPlayerItem = nil
        looper = nil
        
        cancellables.removeAll()
    }
    
    deinit {
        cleanupCurrentPlayer()
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
