import SwiftUI

// MARK: - Create Post View
struct CreatePostView: View {
    @EnvironmentObject var dataController: DataController
    @State private var title = ""
    @State private var pagesLines: [[LineData]] = [[]]
    @State private var currentPageIndex = 0
    @State private var selectedMoods: Set<Mood> = []
    @State private var selectedAlignment: TextAlignment = .center
    @State private var showingPreview = false
    @State private var editMode: EditMode = .simple
    
    enum EditMode {
        case simple
        case advanced
    }
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        pagesLines.contains(where: { pageLines in
            !pageLines.isEmpty && pageLines.contains { !$0.text.isEmpty }
        }) &&
        !selectedMoods.isEmpty &&
        selectedMoods.count <= 3
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                PersistentVideoBackgroundView(backgroundType: background)
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Title Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                TextField("Give your words a title...", text: $title)
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(background.textColor)
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(12)
                            }
                            
                            // Edit Mode Toggle
                            Picker("Edit Mode", selection: $editMode) {
                                Text("Simple").tag(EditMode.simple)
                                Text("Advanced").tag(EditMode.advanced)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            // Page Navigation
                            HStack {
                                Text("Page \(currentPageIndex + 1) of \(pagesLines.count)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button(action: previousPage) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(currentPageIndex > 0 ? background.textColor : background.textColor.opacity(0.3))
                                    }
                                    .disabled(currentPageIndex == 0)
                                    
                                    Button(action: nextPage) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(currentPageIndex < pagesLines.count - 1 ? background.textColor : background.textColor.opacity(0.3))
                                    }
                                    .disabled(currentPageIndex >= pagesLines.count - 1)
                                    
                                    Button(action: addNewPage) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(background.textColor)
                                    }
                                }
                            }
                            
                            // Content Editor based on mode
                            if editMode == .simple {
                                SimpleTextEditor(
                                    lines: $pagesLines[currentPageIndex],
                                    background: background,
                                    textAlignment: selectedAlignment
                                )
                            } else {
                                LineEditorView(
                                    lines: $pagesLines[currentPageIndex],
                                    background: background,
                                    textAlignment: selectedAlignment
                                )
                            }
                            
                            // Text Alignment Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Text Alignment")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                HStack(spacing: 0) {
                                    ForEach(TextAlignment.allCases, id: \.self) { alignment in
                                        Button(action: {
                                            selectedAlignment = alignment
                                        }) {
                                            VStack(spacing: 4) {
                                                Image(systemName: alignment.icon)
                                                    .font(.system(size: 20))
                                                if alignment.isVertical {
                                                    Text("縦書き")
                                                        .font(.system(size: 10))
                                                }
                                            }
                                            .foregroundColor(selectedAlignment == alignment ? .white : background.textColor)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedAlignment == alignment ? Color.blue : Color.clear)
                                        }
                                    }
                                }
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                            }
                            
                            // Mood Selection
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Moods")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(background.textColor)
                                    
                                    Spacer()
                                    
                                    Text("\(selectedMoods.count)/3")
                                        .font(.system(size: 14))
                                        .foregroundColor(background.textColor.opacity(0.7))
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(Mood.allCases, id: \.self) { mood in
                                        MoodSelectionChip(
                                            mood: mood,
                                            isSelected: selectedMoods.contains(mood),
                                            isDisabled: !selectedMoods.contains(mood) && selectedMoods.count >= 3
                                        ) {
                                            if selectedMoods.contains(mood) {
                                                selectedMoods.remove(mood)
                                            } else if selectedMoods.count < 3 {
                                                selectedMoods.insert(mood)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom Actions
                    VStack(spacing: 12) {
                        Button("Preview") {
                            showingPreview = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .foregroundColor(background.textColor)
                        .cornerRadius(12)
                        
                        Button("Share Words") {
                            createPost()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canPost ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(!canPost)
                    }
                    .padding()
                    .background(Color.black.opacity(0.1))
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingPreview) {
            PreviewPostView(
                title: title,
                linesData: pagesLines.filter { !$0.isEmpty },
                moods: Array(selectedMoods),
                textAlignment: selectedAlignment
            )
        }
    }
    
    private func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }
    
    private func nextPage() {
        if currentPageIndex < pagesLines.count - 1 {
            currentPageIndex += 1
        }
    }
    
    private func addNewPage() {
        pagesLines.append([])
        currentPageIndex = pagesLines.count - 1
    }
    
    private func createPost() {
        guard canPost else { return }
        
        let nonEmptyPages = pagesLines.filter { pageLines in
            !pageLines.isEmpty && pageLines.contains { !$0.text.isEmpty }
        }
        
        dataController.createPost(
            title: title,
            linesData: nonEmptyPages,
            moods: Array(selectedMoods),
            textAlignment: selectedAlignment
        )
        
        // Reset form
        title = ""
        pagesLines = [[]]
        currentPageIndex = 0
        selectedMoods = []
        selectedAlignment = .center
        editMode = .simple
    }
}

// MARK: - Simple Text Editor
struct SimpleTextEditor: View {
    @Binding var lines: [LineData]
    let background: BackgroundType
    let textAlignment: TextAlignment
    @State private var textContent: String = ""
    @State private var defaultFontSize: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Default Font Size: \(Int(defaultFontSize))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(background.textColor)
                
                Slider(value: $defaultFontSize, in: 12...36, step: 1)
                    .accentColor(background.textColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Words (press return for new line)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(background.textColor)
                
                TextEditor(text: $textContent)
                    .font(.system(size: 16))
                    .foregroundColor(background.textColor)
                    .frame(minHeight: 250)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(12)
                    .onAppear {
                        textContent = lines.map { $0.text }.joined(separator: "\n")
                        if !lines.isEmpty, let firstLine = lines.first {
                            defaultFontSize = firstLine.fontSize
                        }
                    }
                    .onChange(of: textContent) { oldValue, newValue in
                        let textLines = newValue.components(separatedBy: "\n")
                        lines = textLines.map { lineText in
                            if let existingLine = lines.first(where: { $0.text == lineText }) {
                                return existingLine
                            } else {
                                return LineData(text: lineText, fontSize: defaultFontSize)
                            }
                        }
                    }
                    .onChange(of: defaultFontSize) { oldValue, newValue in
                        lines = lines.map { LineData(text: $0.text, fontSize: newValue) }
                    }
            }
            
            Text("Tip: Switch to Advanced mode to set different font sizes for each line")
                .font(.system(size: 12))
                .foregroundColor(background.textColor.opacity(0.6))
                .italic()
        }
    }
}

// MARK: - Mood Selection Chip
struct MoodSelectionChip: View {
    let mood: Mood
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(mood.icon)
                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Color.blue :
                isDisabled ? Color.gray.opacity(0.3) : Color.white.opacity(0.8)
            )
            .foregroundColor(
                isSelected ? .white :
                isDisabled ? .secondary : .primary
            )
            .cornerRadius(8)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Preview Post View
struct PreviewPostView: View {
    let title: String
    let linesData: [[LineData]]
    let moods: [Mood]
    let textAlignment: TextAlignment
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    @State private var currentPageIndex = 0
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: background)
            
            VStack {
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(background.textColor)
                    
                    Spacer()
                    
                    Text("Preview")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(background.textColor)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44)
                }
                .padding()
                
                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(background.textColor)
                    .padding(.horizontal)
                
                Spacer()
                
                if linesData.count > 1 {
                    TabView(selection: $currentPageIndex) {
                        ForEach(Array(linesData.enumerated()), id: \.offset) { index, pageLines in
                            ScrollView(textAlignment.isVertical ? .horizontal : .vertical) {
                                if textAlignment.isVertical {
                                    VerticalLinesView(
                                        lines: pageLines,
                                        textColor: background.textColor,
                                        maxHeight: UIScreen.main.bounds.height * 0.5
                                    )
                                    .frame(width: UIScreen.main.bounds.width)
                                } else {
                                    VStack(alignment: textAlignmentToHStack(textAlignment), spacing: 8) {
                                        ForEach(Array(pageLines.enumerated()), id: \.offset) { lineIndex, lineData in
                                            Text(lineData.text)
                                                .font(.system(size: lineData.fontSize, weight: .light, design: .serif))
                                                .foregroundColor(background.textColor)
                                                .multilineTextAlignment(textAlignment.swiftUIAlignment)
                                        }
                                    }
                                    .padding(40)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                } else if let firstPage = linesData.first {
                    ScrollView(textAlignment.isVertical ? .horizontal : .vertical) {
                        if textAlignment.isVertical {
                            VerticalLinesView(
                                lines: firstPage,
                                textColor: background.textColor,
                                maxHeight: UIScreen.main.bounds.height * 0.5
                            )
                            .frame(width: UIScreen.main.bounds.width)
                        } else {
                            VStack(alignment: textAlignmentToHStack(textAlignment), spacing: 8) {
                                ForEach(Array(firstPage.enumerated()), id: \.offset) { lineIndex, lineData in
                                    Text(lineData.text)
                                        .font(.system(size: lineData.fontSize, weight: .light, design: .serif))
                                        .foregroundColor(background.textColor)
                                        .multilineTextAlignment(textAlignment.swiftUIAlignment)
                                }
                            }
                            .padding(40)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    ForEach(moods, id: \.self) { mood in
                        Text("\(mood.icon) \(mood.rawValue)")
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.2))
                            .foregroundColor(background.textColor)
                            .cornerRadius(15)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func textAlignmentToHStack(_ alignment: TextAlignment) -> HorizontalAlignment {
        switch alignment {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        case .vertical: return .center
        }
    }
}
