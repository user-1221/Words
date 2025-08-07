// Create new file: LineEditorView.swift

import SwiftUI

struct LineEditorView: View {
    @Binding var lines: [LineData]
    let background: BackgroundType
    let textAlignment: TextAlignment
    @State private var selectedLineIndex: Int?
    @State private var editingText: String = ""
    @State private var editingFontSize: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 12) {
            // Lines display and edit
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        LineItemView(
                            line: line,
                            index: index,
                            isSelected: selectedLineIndex == index,
                            textAlignment: textAlignment,
                            background: background,
                            onTap: {
                                selectLine(index)
                            },
                            onDelete: {
                                deleteLine(at: index)
                            }
                        )
                    }
                    
                    // Add new line button
                    Button(action: addNewLine) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Line")
                        }
                        .foregroundColor(background.textColor.opacity(0.6))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            
            // Edit controls for selected line
            if let index = selectedLineIndex {
                VStack(spacing: 12) {
                    Text("Editing Line \(index + 1)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(background.textColor)
                    
                    // Text input
                    TextField("Enter text for this line", text: $editingText)
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .onChange(of: editingText) { oldValue, newValue in
                            updateCurrentLine()
                        }
                    
                    // Font size control
                    HStack {
                        Text("Font Size: \(Int(editingFontSize))")
                            .font(.system(size: 14))
                            .foregroundColor(background.textColor)
                        
                        Slider(value: $editingFontSize, in: 12...36, step: 1)
                            .accentColor(background.textColor)
                            .onChange(of: editingFontSize) { oldValue, newValue in
                                updateCurrentLine()
                            }
                    }
                    
                    // Preview of current line
                    Text("Preview:")
                        .font(.system(size: 12))
                        .foregroundColor(background.textColor.opacity(0.7))
                    
                    Text(editingText.isEmpty ? "Your text will appear here" : editingText)
                        .font(.system(size: editingFontSize, weight: .light, design: .serif))
                        .foregroundColor(background.textColor)
                        .multilineTextAlignment(textAlignment.swiftUIAlignment)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private func selectLine(_ index: Int) {
        selectedLineIndex = index
        editingText = lines[index].text
        editingFontSize = lines[index].fontSize
    }
    
    private func updateCurrentLine() {
        guard let index = selectedLineIndex else { return }
        lines[index] = LineData(text: editingText, fontSize: editingFontSize)
    }
    
    private func addNewLine() {
        let newLine = LineData(text: "", fontSize: 20)
        lines.append(newLine)
        selectLine(lines.count - 1)
    }
    
    private func deleteLine(at index: Int) {
        lines.remove(at: index)
        if selectedLineIndex == index {
            selectedLineIndex = nil
            editingText = ""
            editingFontSize = 20
        }
    }
}

// MARK: - Line Item View
struct LineItemView: View {
    let line: LineData
    let index: Int
    let isSelected: Bool
    let textAlignment: TextAlignment
    let background: BackgroundType
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text("L\(index + 1)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(background.textColor.opacity(0.5))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                if line.text.isEmpty {
                    Text("Tap to edit this line")
                        .font(.system(size: 14))
                        .foregroundColor(background.textColor.opacity(0.4))
                        .italic()
                } else {
                    Text(line.text)
                        .font(.system(size: line.fontSize, weight: .light, design: .serif))
                        .foregroundColor(background.textColor)
                        .lineLimit(1)
                }
                
                Text("Size: \(Int(line.fontSize))pt")
                    .font(.system(size: 10))
                    .foregroundColor(background.textColor.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.6))
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
}
