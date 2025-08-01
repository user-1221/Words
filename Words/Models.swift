import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - User Preferences Model
struct UserPreferences: Codable {
    var selectedBackground: BackgroundType = .paper
}

// MARK: - Background Type (Now for user preferences)
enum BackgroundType: String, CaseIterable, Codable {
    case paper = "Paper"
    case fog = "Fog"
    case sunset = "Sunset"
    case night = "Night"
    case ocean = "Ocean"
    case forest = "Forest"
    case lavender = "Lavender"
    case mint = "Mint"
    
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
        }
    }
    
    var textColor: Color {
        switch self {
        case .paper, .fog, .lavender, .mint:
            return .black
        case .sunset, .night, .ocean, .forest:
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
