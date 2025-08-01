import Foundation
import Network

// MARK: - Cloudinary Configuration
struct CloudinaryConfig {
    static let cloudName = "dnfhc3fhf"
    
    static let videoBaseURL = "https://res.cloudinary.com/\(cloudName)/video/upload"
    static let imageBaseURL = "https://res.cloudinary.com/\(cloudName)/image/upload"
    
    static let videoTransformations = "q_auto,f_auto,w_1920"
    static let thumbnailTransformations = "so_0,w_400,h_240,c_fill"
    
    static let videoAssets: [BackgroundType: String] = [
        .rainForest: "rain_forest_bg_baxzcs",
        .northernLights: "northern_lights_bg_kigjjm",
        .oceanWaves: "ocean_waves_bg",
        .cloudySky: "cloudy_sky_bg",
        .fireplace: "fireplace_bg",
        .snowfall: "snowfall_bg",
        .cityNight: "city_night_bg",
        .galaxySpace: "galaxy_space_bg"
    ]
    
    // videoURL は URL? 型を返す
    static func videoURL(for background: BackgroundType) -> String? {
        guard let assetName = videoAssets[background] else { return nil }
        return "\(videoBaseURL)/\(videoTransformations)/\(assetName).mp4"
    }
    
    // thumbnailURL も URL? 型を返す
    static func thumbnailURL(for background: BackgroundType) -> String? {
        guard let assetName = videoAssets[background] else { return nil }
        return "\(videoBaseURL)/\(thumbnailTransformations)/\(assetName).jpg"
    }
    
    // フォールバックURL（任意）
    static func safeVideoURL(for background: BackgroundType) -> String {
        return videoURL(for: background) ?? "https://res.cloudinary.com/\(cloudName)/video/upload/f_auto,q_auto/default_fallback.mp4"
    }
}


// MARK: - ネットワーク監視（型・構成変更なし）
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
