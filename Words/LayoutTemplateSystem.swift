import SwiftUI

// MARK: - Text Box Layout Configuration
struct TextBoxLayout {
    let x: CGFloat // 0.0 to 1.0 (percentage of screen width)
    let y: CGFloat // 0.0 to 1.0 (percentage of screen height)
    let width: CGFloat // 0.0 to 1.0 (percentage of screen width)
    let height: CGFloat // 0.0 to 1.0 (percentage of screen height)
    let maxLinesPerPage: Int
    let maxCharactersPerLine: Int
    let preserveEmptyLines: Bool
    
    // Convert to actual frame based on screen size
    func frame(in geometry: GeometryProxy) -> CGRect {
        return CGRect(
            x: geometry.size.width * x,
            y: geometry.size.height * y,
            width: geometry.size.width * width,
            height: geometry.size.height * height
        )
    }
}

// MARK: - Background Layout Mappings (Used by VIEWER, not creator)
struct BackgroundLayoutConfig {
    // Define text box layouts for each background
    static let layouts: [BackgroundType: TextBoxLayout] = [
        // Gradient backgrounds - centered, medium size
        .paper: TextBoxLayout(
            x: 0.1, y: 0.25, width: 0.8, height: 0.5,
            maxLinesPerPage: 12, maxCharactersPerLine: 40, preserveEmptyLines: true
        ),
        .fog: TextBoxLayout(
            x: 0.15, y: 0.3, width: 0.7, height: 0.4,
            maxLinesPerPage: 10, maxCharactersPerLine: 35, preserveEmptyLines: true
        ),
        .sunset: TextBoxLayout(
            x: 0.05, y: 0.6, width: 0.9, height: 0.35,
            maxLinesPerPage: 8, maxCharactersPerLine: 45, preserveEmptyLines: true
        ),
        .night: TextBoxLayout(
            x: 0.2, y: 0.2, width: 0.6, height: 0.6,
            maxLinesPerPage: 14, maxCharactersPerLine: 30, preserveEmptyLines: true
        ),
        .ocean: TextBoxLayout(
            x: 0.1, y: 0.15, width: 0.8, height: 0.4,
            maxLinesPerPage: 10, maxCharactersPerLine: 40, preserveEmptyLines: true
        ),
        .forest: TextBoxLayout(
            x: 0.15, y: 0.5, width: 0.7, height: 0.4,
            maxLinesPerPage: 10, maxCharactersPerLine: 35, preserveEmptyLines: true
        ),
        .lavender: TextBoxLayout(
            x: 0.1, y: 0.35, width: 0.8, height: 0.45,
            maxLinesPerPage: 11, maxCharactersPerLine: 40, preserveEmptyLines: true
        ),
        .mint: TextBoxLayout(
            x: 0.05, y: 0.25, width: 0.9, height: 0.5,
            maxLinesPerPage: 12, maxCharactersPerLine: 45, preserveEmptyLines: true
        ),
        
        // Video backgrounds - varied positions for visual interest
        .rainForest: TextBoxLayout(
            x: 0.1, y: 0.6, width: 0.8, height: 0.35,
            maxLinesPerPage: 8, maxCharactersPerLine: 40, preserveEmptyLines: true
        ),
        .northernLights: TextBoxLayout(
            x: 0.15, y: 0.1, width: 0.7, height: 0.3,
            maxLinesPerPage: 7, maxCharactersPerLine: 35, preserveEmptyLines: true
        ),
        .oceanWaves: TextBoxLayout(
            x: 0.05, y: 0.55, width: 0.9, height: 0.4,
            maxLinesPerPage: 9, maxCharactersPerLine: 45, preserveEmptyLines: true
        ),
        .cloudySky: TextBoxLayout(
            x: 0.2, y: 0.65, width: 0.6, height: 0.3,
            maxLinesPerPage: 7, maxCharactersPerLine: 30, preserveEmptyLines: true
        ),
        .fireplace: TextBoxLayout(
            x: 0.25, y: 0.15, width: 0.5, height: 0.35,
            maxLinesPerPage: 8, maxCharactersPerLine: 25, preserveEmptyLines: true
        ),
        .snowfall: TextBoxLayout(
            x: 0.1, y: 0.2, width: 0.8, height: 0.45,
            maxLinesPerPage: 11, maxCharactersPerLine: 40, preserveEmptyLines: true
        ),
        .cityNight: TextBoxLayout(
            x: 0.05, y: 0.7, width: 0.6, height: 0.25,
            maxLinesPerPage: 6, maxCharactersPerLine: 30, preserveEmptyLines: true
        ),
        .galaxySpace: TextBoxLayout(
            x: 0.3, y: 0.35, width: 0.4, height: 0.3,
            maxLinesPerPage: 7, maxCharactersPerLine: 20, preserveEmptyLines: true
        )
    ]
    
    // Get layout for a background, with fallback
    static func getLayout(for background: BackgroundType) -> TextBoxLayout {
        return layouts[background] ?? TextBoxLayout(
            x: 0.1, y: 0.25, width: 0.8, height: 0.5,
            maxLinesPerPage: 12, maxCharactersPerLine: 40, preserveEmptyLines: true
        )
    }
}

// MARK: - Dynamic Layout Processor (For Viewing Posts)
class DynamicLayoutProcessor {
    
    // Process post content for viewing based on viewer's background
    static func processPostForViewing(
        post: WordPost,
        viewerBackground: BackgroundType,
        geometry: GeometryProxy
    ) -> (pages: [[LineData]], layout: TextBoxLayout) {
        
        let layout = BackgroundLayoutConfig.getLayout(for: viewerBackground)
        
        // If post has structured content, reflow it for current layout
        if let originalPages = post.linesData {
            let allContent = originalPages.flatMap { page in
                page.map { $0.text }
            }.joined(separator: "\n")
            
            let reflowedPages = processContentIntoPages(
                content: allContent,
                layout: layout
            )
            
            // Apply original font sizing pattern if available
            let styledPages = reflowedPages.map { pageLines in
                applyOriginalStyling(
                    lines: pageLines,
                    originalPages: originalPages
                )
            }
            
            return (styledPages, layout)
        }
        
        // Fallback for old posts without structured content
        let content = post.content.joined(separator: "\n")
        let pages = processContentIntoPages(content: content, layout: layout)
        let styledPages = pages.map { pageLines in
            pageLines.map { LineData(text: $0, fontSize: post.fontSize) }
        }
        
        return (styledPages, layout)
    }
    
    // Process content into pages based on layout constraints
    private static func processContentIntoPages(
        content: String,
        layout: TextBoxLayout
    ) -> [[String]] {
        
        var pages: [[String]] = []
        var currentPage: [String] = []
        
        // Split by line breaks, KEEPING empty lines
        let allLines = content.components(separatedBy: "\n")
        
        for line in allLines {
            // Check if adding this line would exceed page limits
            let shouldStartNewPage = currentPage.count >= layout.maxLinesPerPage
            
            if shouldStartNewPage && !currentPage.isEmpty {
                pages.append(currentPage)
                currentPage = []
            }
            
            // Process line based on character limit
            if line.isEmpty && layout.preserveEmptyLines {
                // Keep empty lines for spacing
                currentPage.append("")
            } else if line.count <= layout.maxCharactersPerLine {
                // Line fits within limit
                currentPage.append(line)
            } else {
                // Line needs to be wrapped
                let wrappedLines = wrapLine(line, maxChars: layout.maxCharactersPerLine)
                for wrappedLine in wrappedLines {
                    if currentPage.count >= layout.maxLinesPerPage {
                        pages.append(currentPage)
                        currentPage = []
                    }
                    currentPage.append(wrappedLine)
                }
            }
        }
        
        // Add remaining lines as last page
        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        
        // If no pages created, create one with empty content
        if pages.isEmpty {
            pages.append([""])
        }
        
        return pages
    }
    
    // Wrap line at word boundaries
    private static func wrapLine(_ line: String, maxChars: Int) -> [String] {
        guard !line.isEmpty && maxChars > 0 else { return [line] }
        
        var result: [String] = []
        var currentLine = ""
        let words = line.split(separator: " ", omittingEmptySubsequences: false)
        
        for word in words {
            let wordStr = String(word)
            
            if currentLine.isEmpty {
                currentLine = wordStr
            } else if currentLine.count + 1 + wordStr.count <= maxChars {
                currentLine += " " + wordStr
            } else {
                result.append(currentLine)
                currentLine = wordStr
            }
            
            // Handle very long words
            while currentLine.count > maxChars {
                let index = currentLine.index(currentLine.startIndex, offsetBy: maxChars)
                result.append(String(currentLine[..<index]))
                currentLine = String(currentLine[index...])
            }
        }
        
        if !currentLine.isEmpty {
            result.append(currentLine)
        }
        
        return result.isEmpty ? [""] : result
    }
    
    // Apply original styling pattern to reflowed content
    private static func applyOriginalStyling(
        lines: [String],
        originalPages: [[LineData]]
    ) -> [LineData] {
        
        // Get all original font sizes (excluding empty lines)
        let originalSizes = originalPages.flatMap { page in
            page.filter { !$0.text.isEmpty }.map { $0.fontSize }
        }
        
        guard !originalSizes.isEmpty else {
            return lines.map { LineData(text: $0, fontSize: 20) }
        }
        
        // Calculate size pattern
        let minSize = originalSizes.min() ?? 16
        let maxSize = originalSizes.max() ?? 28
        
        var styledLines: [LineData] = []
        
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                styledLines.append(LineData(text: line, fontSize: minSize))
            } else {
                // Apply a pattern based on position
                let progress = lines.count > 1 ? CGFloat(index) / CGFloat(lines.count - 1) : 0.5
                let fontSize = maxSize - (progress * (maxSize - minSize) * 0.6)
                styledLines.append(LineData(text: line, fontSize: fontSize))
            }
        }
        
        return styledLines
    }
}
