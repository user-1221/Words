import SwiftUI

// MARK: - Vertical Lines View
struct VerticalLinesView: View {
    let lines: [LineData]
    let textColor: Color
    let maxHeight: CGFloat
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            ForEach(Array(lines.reversed().enumerated()), id: \.offset) { index, lineData in
                VStack(spacing: 4) {
                    ForEach(Array(lineData.text.enumerated()), id: \.offset) { charIndex, char in
                        Text(String(char))
                            .font(.system(size: lineData.fontSize, weight: .light, design: .serif))
                            .foregroundColor(textColor)
                            .frame(width: lineData.fontSize * 1.2)
                    }
                }
            }
        }
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 20) // Optional
    }
}


// MARK: - Vertical Text View (Original - for backward compatibility)
struct VerticalTextView: View {
    let text: String
    let fontSize: CGFloat
    let textColor: Color
    let maxHeight: CGFloat
    
    private var charactersPerColumn: Int {
        let lineHeight = fontSize * 1.5
        return Int(maxHeight / lineHeight)
    }
    
    private var columns: [[String]] {
        let characters = Array(text)
        var result: [[String]] = []
        var currentColumn: [String] = []
        
        for char in characters {
            if char == "\n" {
                result.append(currentColumn)
                currentColumn = []
            } else {
                currentColumn.append(String(char))
                if currentColumn.count >= charactersPerColumn {
                    result.append(currentColumn)
                    currentColumn = []
                }
            }
        }
        
        if !currentColumn.isEmpty {
            result.append(currentColumn)
        }
        
        return result.reversed()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: fontSize * 0.8) {
            ForEach(0..<columns.count, id: \.self) { columnIndex in
                VStack(spacing: 2) {
                    ForEach(0..<columns[columnIndex].count, id: \.self) { charIndex in
                        Text(columns[columnIndex][charIndex])
                            .font(.system(size: fontSize, weight: .light, design: .serif))
                            .foregroundColor(textColor)
                            .frame(width: fontSize * 1.2)
                    }
                }
            }
        }
    }
}

// MARK: - Adaptive Text View (Helper)
struct AdaptiveTextView: View {
    let text: String
    let fontSize: CGFloat
    let textColor: Color
    let alignment: TextAlignment
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    
    var body: some View {
        if alignment.isVertical {
            ScrollView(.horizontal, showsIndicators: false) {
                VerticalTextView(
                    text: text,
                    fontSize: fontSize,
                    textColor: textColor,
                    maxHeight: maxHeight
                )
                .padding(.horizontal, 20)
            }
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(textColor)
                .multilineTextAlignment(alignment.swiftUIAlignment)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
