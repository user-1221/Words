import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - User Preferences Model
struct UserPreferences: Codable {
    var selectedBackground: BackgroundType = .paper
    var backgroundVideoURL: String?
    var backgroundThumbnailURL: String?
}

// MARK: - Background Type (Now supports videos)
enum BackgroundType: String, CaseIterable, Codable {
    // Original gradient backgrounds
    case paper = "Paper"
    case fog = "Fog"
    case sunset = "Sunset"
    case night = "Night"
    case ocean = "Ocean"
    case forest = "Forest"
    case lavender = "Lavender"
    case mint = "Mint"
    
    // Video backgrounds
    case rainForest = "Rain Forest"
    case northernLights = "Northern Lights"
    case oceanWaves = "Ocean Waves"
    case cloudySky = "Cloudy Sky"
    case fireplace = "Fireplace"
    case snowfall = "Snowfall"
    case cityNight = "City Night"
    case galaxySpace = "Galaxy Space"
    
    var isVideo: Bool {
        switch self {
        case .rainForest, .northernLights, .oceanWaves, .cloudySky,
             .fireplace, .snowfall, .cityNight, .galaxySpace:
            return true
        default:
            return false
        }
    }
    
    // Cloudinary video URLs
    var videoURL: String? {
        return CloudinaryConfig.videoURL(for: self)
    }
    
    // Thumbnail URLs for video previews
    var thumbnailURL: String? {
        return CloudinaryConfig.thumbnailURL(for: self)
    }
    
    var gradient: LinearGradient {
        switch self {
        case .paper:
            return LinearGradient(
                colors: [Color(hex: "F5F5DC"), Color(hex: "E8E8D5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .fog:
            return LinearGradient(
                colors: [Color(hex: "E0E0E0"), Color(hex: "F5F5F5")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .sunset:
            return LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "FFE66D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .night:
            return LinearGradient(
                colors: [Color(hex: "2C3E50"), Color(hex: "34495E")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .ocean:
            return LinearGradient(
                colors: [Color(hex: "4CA1AF"), Color(hex: "2C3E50")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .forest:
            return LinearGradient(
                colors: [Color(hex: "134E5E"), Color(hex: "71B280")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .lavender:
            return LinearGradient(
                colors: [Color(hex: "E8D5E8"), Color(hex: "C8A8D8")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .mint:
            return LinearGradient(
                colors: [Color(hex: "A8E6CF"), Color(hex: "7FCDBB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        // Fallback gradients for video backgrounds
        case .rainForest:
            return LinearGradient(
                colors: [Color(hex: "0F2027"), Color(hex: "203A43"), Color(hex: "2C5364")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .northernLights:
            return LinearGradient(
                colors: [Color(hex: "00C9FF"), Color(hex: "92FE9D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .oceanWaves:
            return LinearGradient(
                colors: [Color(hex: "2E3192"), Color(hex: "1BFFFF")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cloudySky:
            return LinearGradient(
                colors: [Color(hex: "757F9A"), Color(hex: "D7DDE8")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .fireplace:
            return LinearGradient(
                colors: [Color(hex: "F83600"), Color(hex: "FE8C00")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .snowfall:
            return LinearGradient(
                colors: [Color(hex: "E6DADA"), Color(hex: "274046")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .cityNight:
            return LinearGradient(
                colors: [Color(hex: "0F0C29"), Color(hex: "302B63"), Color(hex: "24243E")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .galaxySpace:
            return LinearGradient(
                colors: [Color(hex: "000428"), Color(hex: "004E92")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var textColor: Color {
        switch self {
        case .paper, .fog, .lavender, .mint, .cloudySky:
            return .black
        case .sunset, .night, .ocean, .forest, .rainForest,
             .northernLights, .oceanWaves, .fireplace, .snowfall,
             .cityNight, .galaxySpace:
            return .white
        }
    }
}

// MARK: - Word Post Model (Simplified - no background)
struct WordPost: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let content: [String] // Array for multi-page support
    let moods: [Mood]
    let fontSize: CGFloat
    let createdAt: Date
    let authorId: String
    var appreciationCount: Int = 0
}

// MARK: - Mood Enum
enum Mood: String, CaseIterable, Codable {
    case motivational = "Motivational"
    case peaceful = "Peaceful"
    case hopecore = "Hopecore"
    case melancholy = "Melancholy"
    case existential = "Existential"
    case healing = "Healing"
    case unfiltered = "Unfiltered"
    case grounding = "Grounding"
    case playful = "Playful"
    case surreal = "Surreal"
    
    var icon: String {
        switch self {
        case .motivational: return "💪"
        case .peaceful: return "🕊"
        case .hopecore: return "✨"
        case .melancholy: return "🌧"
        case .existential: return "🌌"
        case .healing: return "🌱"
        case .unfiltered: return "💭"
        case .grounding: return "🌍"
        case .playful: return "🎈"
        case .surreal: return "🌀"
        }
    }
}

// MARK: - Appreciation Message Model
struct AppreciationMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let postId: String
    let postContent: String?
    let message: String
    let sentAt: Date
    let senderId: String
    let receiverId: String
    var isRead: Bool = false
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
