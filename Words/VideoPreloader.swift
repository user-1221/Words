import SwiftUI
import AVKit

// MARK: - Video Preloader
// This helps preload video assets for smoother transitions

class VideoPreloader: ObservableObject {
    static let shared = VideoPreloader()
    
    @Published var preloadedPlayers: [BackgroundType: AVPlayer] = [:]
    @Published var preloadProgress: [BackgroundType: Double] = [:]
    
    private init() {}
    
    // Preload a specific video
    func preloadVideo(for backgroundType: BackgroundType) {
        guard backgroundType.isVideo,
              let urlString = backgroundType.videoURL,
              let url = URL(string: urlString),
              preloadedPlayers[backgroundType] == nil else { return }
        
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        
        // Observe loading progress
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.preloadedPlayers[backgroundType] = player
                    self?.preloadProgress[backgroundType] = 1.0
                case .failed:
                    self?.preloadProgress[backgroundType] = 0.0
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe buffering progress
        playerItem.publisher(for: \.loadedTimeRanges)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRanges in
                guard let firstRange = timeRanges.first?.timeRangeValue else { return }
                let loadedDuration = CMTimeGetSeconds(firstRange.duration)
                let totalDuration = CMTimeGetSeconds(playerItem.duration)
                
                if totalDuration > 0 {
                    let progress = min(loadedDuration / totalDuration, 1.0)
                    self?.preloadProgress[backgroundType] = progress
                }
            }
            .store(in: &cancellables)
    }
    
    // Preload all video backgrounds
    func preloadAllVideos() {
        let videoBackgrounds = BackgroundType.allCases.filter { $0.isVideo }
        for background in videoBackgrounds {
            preloadVideo(for: background)
        }
    }
    
    // Get preloaded player
    func getPlayer(for backgroundType: BackgroundType) -> AVPlayer? {
        return preloadedPlayers[backgroundType]
    }
    
    // Clean up resources
    func cleanup() {
        for (_, player) in preloadedPlayers {
            player.pause()
        }
        preloadedPlayers.removeAll()
        preloadProgress.removeAll()
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Enhanced Video Background View
struct EnhancedVideoBackgroundView: View {
    let backgroundType: BackgroundType
    @StateObject private var preloader = VideoPreloader.shared
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        ZStack {
            if backgroundType.isVideo {
                // Check for preloaded player first
                if let preloadedPlayer = preloader.getPlayer(for: backgroundType) {
                    VideoPlayer(player: preloadedPlayer)
                        .disabled(true)
                        .ignoresSafeArea()
                        .onAppear {
                            preloadedPlayer.seek(to: .zero)
                            preloadedPlayer.play()
                            isLoading = false
                        }
                        .onDisappear {
                            preloadedPlayer.pause()
                        }
                }
            } else {
                // Regular gradient background
                backgroundType.gradient
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Preload on App Launch
// Add this to your WordsApp.swift init():
/*
init() {
    FirebaseApp.configure()
    
    // Preload video backgrounds in the background
    DispatchQueue.global(qos: .background).async {
        VideoPreloader.shared.preloadAllVideos()
    }
}
*/

// Import Combine
import Combine
