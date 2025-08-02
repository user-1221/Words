import Foundation
import UIKit

// MARK: - Video Configuration
// Easy to add new videos - just add to videoDatabase
struct VideoConfig {
    static let cloudName = "dnfhc3fhf"
    
    static let videoBaseURL = "https://res.cloudinary.com/\(cloudName)/video/upload"
    static let imageBaseURL = "https://res.cloudinary.com/\(cloudName)/image/upload"
    
    // Video quality settings
    static let videoTransformations = "q_auto,f_mp4,w_1920"
    static let thumbnailTransformations = "so_0,w_400,h_240,c_fill"
    
    // MARK: - Video Database
    // To add new videos: Just add a new entry here with BackgroundType and asset name
    static let videoDatabase: [BackgroundType: VideoAsset] = [
        .rainForest: VideoAsset(
            cloudinaryId: "rain_forest_bg_baxzcs",
            displayName: "Rain Forest",
            duration: 30
        ),
        .northernLights: VideoAsset(
            cloudinaryId: "northern_lights_bg_kigjjm",
            displayName: "Northern Lights",
            duration: 60
        ),
        .oceanWaves: VideoAsset(
            cloudinaryId: "ocean_waves_bg_yszqcx",
            displayName: "Ocean Waves",
            duration: 45
        ),
        .cloudySky: VideoAsset(
            cloudinaryId: "cloudy_sky_bg_gqheqs",
            displayName: "Cloudy Sky",
            duration: 40
        ),
        .fireplace: VideoAsset(
            cloudinaryId: "fireplace_bg_tfqkjd",
            displayName: "Fireplace",
            duration: 50
        ),
        .snowfall: VideoAsset(
            cloudinaryId: "snowfall_bg_vbgyf0",
            displayName: "Snowfall",
            duration: 35
        ),
        .cityNight: VideoAsset(
            cloudinaryId: "city_night_bg_ixqpwd",
            displayName: "City Night",
            duration: 55
        ),
        .galaxySpace: VideoAsset(
            cloudinaryId: "galaxy_space_bg_kmyq1i",
            displayName: "Galaxy Space",
            duration: 70
        )
    ]
    
    // Get video URL
    static func videoURL(for background: BackgroundType) -> String? {
        guard let asset = videoDatabase[background] else { return nil }
        return "\(videoBaseURL)/\(videoTransformations)/\(asset.cloudinaryId).mp4"
    }
    
    // Get thumbnail URL
    static func thumbnailURL(for background: BackgroundType) -> String? {
        guard let asset = videoDatabase[background] else { return nil }
        return "\(videoBaseURL)/\(thumbnailTransformations)/\(asset.cloudinaryId).jpg"
    }
    
    // Fallback video URL
    static func fallbackVideoURL() -> String {
        return "https://res.cloudinary.com/\(cloudName)/video/upload/f_auto,q_auto/samples/sea-turtle.mp4"
    }
    
    // Check if URL is valid
    static func isValidVideoURL(_ urlString: String?) -> Bool {
        guard let urlString = urlString,
              let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - Video Asset Model
struct VideoAsset {
    let cloudinaryId: String
    let displayName: String
    let duration: TimeInterval // in seconds
    
    var videoURL: String {
        return "\(VideoConfig.videoBaseURL)/\(VideoConfig.videoTransformations)/\(cloudinaryId).mp4"
    }
    
    var thumbnailURL: String {
        return "\(VideoConfig.videoBaseURL)/\(VideoConfig.thumbnailTransformations)/\(cloudinaryId).jpg"
    }
}

// MARK: - BackgroundType Extension for Video
extension BackgroundType {
    var videoURL: String? {
        return VideoConfig.videoURL(for: self)
    }
    
    var thumbnailURL: String? {
        return VideoConfig.thumbnailURL(for: self)
    }
    
    var videoAsset: VideoAsset? {
        return VideoConfig.videoDatabase[self]
    }
}
