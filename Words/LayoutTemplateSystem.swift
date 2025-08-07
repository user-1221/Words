import SwiftUI

// MARK: - Layout Template System
enum LayoutTemplate: String, CaseIterable {
    case cascade = "Cascade"
    case emphasis = "Emphasis"
    case rhythm = "Rhythm"
    case climax = "Climax"
    case scattered = "Scattered"
    case minimal = "Minimal"
    case dramatic = "Dramatic"
    case wave = "Wave"
    case staircase = "Staircase"
    case balanced = "Balanced"
    
    var description: String {
        switch self {
        case .cascade: return "Gradually decreasing sizes"
        case .emphasis: return "Bold first line"
        case .rhythm: return "Alternating sizes"
        case .climax: return "Build to middle"
        case .scattered: return "Random variation"
        case .minimal: return "Subtle differences"
        case .dramatic: return "High contrast"
        case .wave: return "Flowing pattern"
        case .staircase: return "Step-like progression"
        case .balanced: return "Harmonious sizing"
        }
    }
}

// MARK: - Template Engine
class TemplateEngine {
    
    // MARK: - Main Generation Function
    static func generateStyledLayout(
        title: String,
        content: String,
        moods: [Mood],
        alignment: TextAlignment,
        seed: Int? = nil
    ) -> (linesData: [[LineData]], layoutSeed: Int, templateName: String) {
        
        // Generate or use provided seed
        let layoutSeed = seed ?? Int.random(in: 0...99999)
        var generator = SeededRandomNumberGenerator(seed: layoutSeed)
        
        // Split content into pages and lines
        let pages = content.components(separatedBy: "\n\n\n") // Three returns = page break
        let processedPages = pages.map { page in
            page.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        
        // Select template based on seed and mood
        let template = selectTemplate(moods: moods, using: &generator)
        
        // Generate styled lines for each page
        let styledPages = processedPages.map { pageLines in
            applyTemplate(
                lines: pageLines,
                template: template,
                moods: moods,
                using: &generator
            )
        }
        
        return (styledPages, layoutSeed, template.rawValue)
    }
    
    // MARK: - Template Selection
    private static func selectTemplate(
        moods: [Mood],
        using generator: inout SeededRandomNumberGenerator
    ) -> LayoutTemplate {
        
        // Mood-based template preferences
        var preferredTemplates: [LayoutTemplate] = []
        
        for mood in moods {
            switch mood {
            case .peaceful:
                preferredTemplates.append(contentsOf: [.minimal, .wave, .balanced])
            case .motivational:
                preferredTemplates.append(contentsOf: [.emphasis, .dramatic, .climax])
            case .melancholy:
                preferredTemplates.append(contentsOf: [.cascade, .wave, .scattered])
            case .hopecore:
                preferredTemplates.append(contentsOf: [.climax, .staircase, .rhythm])
            case .existential:
                preferredTemplates.append(contentsOf: [.scattered, .minimal, .wave])
            case .playful:
                preferredTemplates.append(contentsOf: [.rhythm, .scattered, .staircase])
            case .healing:
                preferredTemplates.append(contentsOf: [.balanced, .minimal, .wave])
            case .grounding:
                preferredTemplates.append(contentsOf: [.balanced, .minimal, .emphasis])
            case .surreal:
                preferredTemplates.append(contentsOf: [.scattered, .dramatic, .wave])
            case .unfiltered:
                preferredTemplates.append(contentsOf: [.dramatic, .emphasis, .scattered])
            }
        }
        
        // If no preferences, use all templates
        if preferredTemplates.isEmpty {
            preferredTemplates = Array(LayoutTemplate.allCases)
        }
        
        // Random selection from preferred templates
        let index = Int.random(in: 0..<preferredTemplates.count, using: &generator)
        return preferredTemplates[index]
    }
    
    // MARK: - Apply Template to Lines
    private static func applyTemplate(
        lines: [String],
        template: LayoutTemplate,
        moods: [Mood],
        using generator: inout SeededRandomNumberGenerator
    ) -> [LineData] {
        
        guard !lines.isEmpty else { return [] }
        
        // Get font size range based on mood
        let (minSize, maxSize) = getFontSizeRange(for: moods)
        
        var styledLines: [LineData] = []
        
        for (index, line) in lines.enumerated() {
            let fontSize = calculateFontSize(
                text: line,
                lineIndex: index,
                totalLines: lines.count,
                template: template,
                minSize: minSize,
                maxSize: maxSize,
                using: &generator
            )
            
            styledLines.append(LineData(text: line, fontSize: fontSize))
        }
        
        return styledLines
    }
    
    // MARK: - Calculate Font Size
    private static func calculateFontSize(
        text: String,
        lineIndex: Int,
        totalLines: Int,
        template: LayoutTemplate,
        minSize: CGFloat,
        maxSize: CGFloat,
        using generator: inout SeededRandomNumberGenerator
    ) -> CGFloat {
        
        let progress = totalLines > 1 ? CGFloat(lineIndex) / CGFloat(totalLines - 1) : 0.5
        let textLength = text.count
        
        // Length-based adjustment (shorter lines can be larger)
        let lengthMultiplier: CGFloat
        if textLength < 20 {
            lengthMultiplier = 1.2
        } else if textLength < 40 {
            lengthMultiplier = 1.0
        } else if textLength < 60 {
            lengthMultiplier = 0.9
        } else {
            lengthMultiplier = 0.8
        }
        
        // Template-specific sizing
        let templateSize: CGFloat
        
        switch template {
        case .cascade:
            // Gradually decrease
            templateSize = maxSize - (progress * (maxSize - minSize))
            
        case .emphasis:
            // First line large, rest medium
            if lineIndex == 0 {
                templateSize = maxSize
            } else {
                templateSize = minSize + (maxSize - minSize) * 0.4
            }
            
        case .rhythm:
            // Alternating pattern
            if lineIndex % 2 == 0 {
                templateSize = maxSize * 0.9
            } else {
                templateSize = minSize + (maxSize - minSize) * 0.3
            }
            
        case .climax:
            // Build to middle
            let middle = CGFloat(totalLines) / 2
            let distanceFromMiddle = abs(CGFloat(lineIndex) - middle) / middle
            templateSize = maxSize - (distanceFromMiddle * (maxSize - minSize) * 0.7)
            
        case .scattered:
            // Random but balanced
            let randomFactor = CGFloat.random(in: 0.3...1.0, using: &generator)
            templateSize = minSize + (maxSize - minSize) * randomFactor
            
        case .minimal:
            // Mostly uniform with subtle variations
            let variation = CGFloat.random(in: -0.1...0.1, using: &generator)
            let baseSize = minSize + (maxSize - minSize) * 0.5
            templateSize = baseSize + (baseSize * variation)
            
        case .dramatic:
            // High contrast
            if lineIndex % 3 == 0 {
                templateSize = maxSize
            } else {
                templateSize = minSize
            }
            
        case .wave:
            // Sine wave pattern
            let wavePosition = sin(progress * .pi * 2)
            templateSize = minSize + (maxSize - minSize) * (0.5 + wavePosition * 0.5)
            
        case .staircase:
            // Step progression
            let steps = min(5, totalLines)
            let step = lineIndex * steps / totalLines
            templateSize = minSize + (CGFloat(step) / CGFloat(steps - 1)) * (maxSize - minSize)
            
        case .balanced:
            // Harmonious golden ratio
            if lineIndex == 0 {
                templateSize = maxSize * 0.8
            } else if lineIndex == totalLines - 1 {
                templateSize = maxSize * 0.8
            } else {
                templateSize = minSize + (maxSize - minSize) * 0.5
            }
        }
        
        // Apply length multiplier and clamp to range
        let finalSize = min(maxSize, max(minSize, templateSize * lengthMultiplier))
        
        // Round to nearest even number for cleaner rendering
        return round(finalSize / 2) * 2
    }
    
    // MARK: - Font Size Range
    private static func getFontSizeRange(for moods: [Mood]) -> (min: CGFloat, max: CGFloat) {
        var minSize: CGFloat = 16
        var maxSize: CGFloat = 32
        
        // Adjust range based on moods
        for mood in moods {
            switch mood {
            case .peaceful:
                minSize = max(minSize, 16)
                maxSize = min(maxSize, 24)
            case .motivational:
                minSize = max(minSize, 18)
                maxSize = max(maxSize, 36)
                /*
            case .dramatic:
                minSize = max(minSize, 14)
                maxSize = max(maxSize, 36)
            case .minimal:
                minSize = max(minSize, 18)
                maxSize = min(maxSize, 22)
                 */
            case .playful:
                minSize = max(minSize, 16)
                maxSize = max(maxSize, 32)
            case .melancholy:
                minSize = max(minSize, 16)
                maxSize = min(maxSize, 28)
            case .existential:
                minSize = max(minSize, 14)
                maxSize = min(maxSize, 26)
            case .healing:
                minSize = max(minSize, 18)
                maxSize = min(maxSize, 26)
            case .grounding:
                minSize = max(minSize, 20)
                maxSize = min(maxSize, 28)
            case .hopecore:
                minSize = max(minSize, 18)
                maxSize = max(maxSize, 32)
            case .surreal:
                minSize = max(minSize, 14)
                maxSize = max(maxSize, 34)
            case .unfiltered:
                minSize = max(minSize, 16)
                maxSize = max(maxSize, 32)
            }
        }
        
        // Ensure valid range
        if minSize > maxSize {
            let avg = (minSize + maxSize) / 2
            minSize = avg - 4
            maxSize = avg + 4
        }
        
        return (minSize, maxSize)
    }
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var seed: UInt64
    
    init(seed: Int) {
        self.seed = UInt64(abs(seed))
    }
    
    mutating func next() -> UInt64 {
        seed = (seed &* 1664525) &+ 1013904223
        return seed
    }
}

// MARK: - CGFloat Random Extension
extension CGFloat {
    static func random(in range: ClosedRange<CGFloat>, using generator: inout SeededRandomNumberGenerator) -> CGFloat {
        let randomValue = CGFloat(generator.next()) / CGFloat(UInt64.max)
        return range.lowerBound + (randomValue * (range.upperBound - range.lowerBound))
    }
}

// MARK: - Int Random Extension
extension Int {
    static func random(in range: Range<Int>, using generator: inout SeededRandomNumberGenerator) -> Int {
        let randomValue = generator.next()
        let rangeSize = UInt64(range.upperBound - range.lowerBound)
        let boundedValue = randomValue % rangeSize
        return range.lowerBound + Int(boundedValue)
    }
}
