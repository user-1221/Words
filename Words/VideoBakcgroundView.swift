import SwiftUI
import AVKit

// MARK: - Persistent Video Background View
struct PersistentVideoBackgroundView: View {
    let backgroundType: BackgroundType
    @StateObject private var videoManager = VideoBackgroundManager.shared
    @State private var isInitialized = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if backgroundType.isVideo {
                    if let player = videoManager.currentPlayer,
                       videoManager.currentBackgroundType == backgroundType,
                       !videoManager.hasError {
                        VideoPlayerView(player: player, geometry: geometry)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    } else if videoManager.isLoading && videoManager.currentBackgroundType == backgroundType {
                        LoadingVideoView(backgroundType: backgroundType)
                    } else {
                        // Show gradient with retry
                        ZStack {
                            backgroundType.gradient
                                .ignoresSafeArea()
                            
                            if backgroundType.isVideo && !isInitialized {
                                Color.clear
                                    .onAppear {
                                        isInitialized = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            videoManager.loadVideo(for: backgroundType)
                                        }
                                    }
                            }
                        }
                    }
                } else {
                    // Regular gradient background
                    backgroundType.gradient
                        .ignoresSafeArea()
                        .onAppear {
                            if videoManager.currentBackgroundType?.isVideo == true {
                                videoManager.cleanupCurrentPlayer()
                            }
                        }
                }
            }
        }
        .onChange(of: backgroundType) { oldValue, newValue in
            if newValue.isVideo {
                videoManager.loadVideo(for: newValue)
            } else if oldValue.isVideo {
                videoManager.cleanupCurrentPlayer()
            }
        }
    }
}
// MARK: - Loading Video View
struct LoadingVideoView: View {
    let backgroundType: BackgroundType
    
    var body: some View {
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
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
}

// MARK: - Custom Video Player View
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    let geometry: GeometryProxy
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.updatePlayerLayer(size: geometry.size)
    }
    
    class PlayerUIView: UIView {
        var player: AVPlayer? {
            didSet {
                setupPlayerLayer()
            }
        }
        
        private var playerLayer: AVPlayerLayer?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupPlayerLayer() {
            playerLayer?.removeFromSuperlayer()
            
            guard let player = player else { return }
            
            let newPlayerLayer = AVPlayerLayer(player: player)
            newPlayerLayer.videoGravity = .resizeAspectFill
            newPlayerLayer.frame = bounds
            
            layer.addSublayer(newPlayerLayer)
            playerLayer = newPlayerLayer
            
            player.play()
        }
        
        func updatePlayerLayer(size: CGSize) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer?.frame = CGRect(origin: .zero, size: size)
            CATransaction.commit()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer?.frame = bounds
        }
    }
}

// MARK: - Background Selection Card
struct BackgroundSelectionCard: View {
    let background: BackgroundType
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if background.isVideo {
                        // Show thumbnail for video backgrounds
                        AsyncImage(url: URL(string: background.thumbnailURL ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_):
                                // Fallback gradient on thumbnail load failure
                                background.gradient
                            case .empty:
                                // Loading state
                                ZStack {
                                    background.gradient
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            @unknown default:
                                background.gradient
                            }
                        }
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        
                        // Video indicator overlay
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "video.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    } else {
                        // Regular gradient preview
                        background.gradient
                            .frame(height: 120)
                            .cornerRadius(12)
                    }
                    
                    if isLoading {
                        ZStack {
                            Color.black.opacity(0.6)
                                .cornerRadius(12)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    } else if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 3)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                    }
                }
                
                Text(background.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
