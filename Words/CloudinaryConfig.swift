import Foundation
import Network

// MARK: - Cloudinary Configuration
struct CloudinaryConfig {
    static let cloudName = "dnfhc3fhf"
    
    static let videoBaseURL = "https://res.cloudinary.com/\(cloudName)/video/upload"
    static let imageBaseURL = "https://res.cloudinary.com/\(cloudName)/image/upload"
    
    static let videoTransformations = "q_auto,f_mp4,w_1920"
    static let thumbnailTransformations = "so_0,w_400,h_240,c_fill"
    
    static let videoAssets: [BackgroundType: String] = [
        .rainForest: "rain_forest_bg_baxzcs",
        .northernLights: "northern_lights_bg_kigjjm",
        .oceanWaves: "ocean_waves_bg_yszqcx",
        .cloudySky: "cloudy_sky_bg_gqheqs",
        .fireplace: "fireplace_bg_tfqkjd",
        .snowfall: "snowfall_bg_vbgyf0",
        .cityNight: "city_night_bg_ixqpwd",
        .galaxySpace: "galaxy_space_bg_kmyq1i"
    ]
    
    // Return String directly, not URL?
    static func videoURL(for background: BackgroundType) -> String? {
        guard let assetName = videoAssets[background] else { return nil }
        return "\(videoBaseURL)/\(videoTransformations)/\(assetName).mp4"
    }
    
    // Return String directly, not URL?
    static func thumbnailURL(for background: BackgroundType) -> String? {
        guard let assetName = videoAssets[background] else { return nil }
        return "\(videoBaseURL)/\(thumbnailTransformations)/\(assetName).jpg"
    }
    
    // Fallback URL
    static func safeVideoURL(for background: BackgroundType) -> String {
        // Use a simple test video as fallback
        return "https://res.cloudinary.com/\(cloudName)/video/upload/f_auto,q_auto/samples/sea-turtle.mp4"
    }
}

// MARK: - Network Monitor
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
