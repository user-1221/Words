import SwiftUI

// MARK: - Create Post View (Simplified with Auto-Styling)
struct CreatePostView: View {
    @EnvironmentObject var dataController: DataController
    @State private var title = ""
    @State private var content = ""
    @State private var selectedMoods: Set<Mood> = []
    @State private var selectedAlignment: TextAlignment = .center
    @State private var showingPreview = false
    
    // Generated layout data
    @State private var generatedLinesData: [[LineData]] = []
    @State private var currentLayoutSeed: Int = 0
    @State private var currentTemplateName: String = ""
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedMoods.isEmpty &&
        selectedMoods.count <= 3
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                PersistentVideoBackgroundView(backgroundType: background)
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Text("Create Your Words")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(background.textColor)
                                
                                Text("Just write. We'll make it beautiful.")
                                    .font(.system(size: 16))
                                    .foregroundColor(background.textColor.opacity(0.7))
                            }
                            .padding(.top, 20)
                            
                            // Title Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                TextField("Give your words a title...", text: $title)
                                    .font(.system(size: 20))
                                    .foregroundColor(background.textColor)
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(12)
                            }
                            
                            // Content Input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Your Words")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(background.textColor)
                                    
                                    Spacer()
                                    
                                    Text("\(content.count) characters")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                }
                                
                                TextEditor(text: $content)
                                    .font(.system(size: 16))
                                    .foregroundColor(background.textColor)
                                    .scrollContentBackground(.hidden)
                                    .padding()
                                    .frame(minHeight: 250)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("💡 Tips:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(background.textColor.opacity(0.8))
                                    
                                    Text("• Press return for a new line")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                    
                                    Text("• Press return 3 times for a new page")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                    
                                    Text("• Keep lines short for more impact")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                }
                                .padding(.horizontal, 8)
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
                                    
                                    Text("\(selectedMoods.count)/3 selected")
                                        .font(.system(size: 14))
                                        .foregroundColor(background.textColor.opacity(0.7))
                                }
                                
                                Text("Moods influence the visual style")
                                    .font(.system(size: 12))
                                    .foregroundColor(background.textColor.opacity(0.6))
                                
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
                            generateLayout()
                            showingPreview = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canPost ? Color.white.opacity(0.8) : Color.gray.opacity(0.3))
                        .foregroundColor(canPost ? background.textColor : background.textColor.opacity(0.5))
                        .cornerRadius(12)
                        .disabled(!canPost)
                        
                        Button("Share Words") {
                            if canPost && !generatedLinesData.isEmpty {
                                createPost()
                            } else {
                                generateLayout()
                                if !generatedLinesData.isEmpty {
                                    createPost()
                                }
                            }
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
            AutoStyledPreviewView(
                title: title,
                linesData: generatedLinesData,
                moods: Array(selectedMoods),
                textAlignment: selectedAlignment,
                templateName: currentTemplateName,
                onRegenerate: {
                    generateLayout()
                },
                onConfirm: {
                    showingPreview = false
                    createPost()
                }
            )
        }
    }
    
    // MARK: - Generate Layout
    private func generateLayout() {
        let result = TemplateEngine.generateStyledLayout(
            title: title,
            content: content,
            moods: Array(selectedMoods),
            alignment: selectedAlignment,
            seed: nil // Will generate random seed
        )
        
        generatedLinesData = result.linesData
        currentLayoutSeed = result.layoutSeed
        currentTemplateName = result.templateName
    }
    
    // MARK: - Create Post
    private func createPost() {
        guard canPost else { return }
        
        // Generate layout if not already done
        if generatedLinesData.isEmpty {
            generateLayout()
        }
        
        dataController.createPost(
            title: title,
            linesData: generatedLinesData,
            moods: Array(selectedMoods),
            textAlignment: selectedAlignment,
            layoutSeed: currentLayoutSeed,
            templateName: currentTemplateName
        )
        
        // Reset form
        title = ""
        content = ""
        selectedMoods = []
        selectedAlignment = .center
        generatedLinesData = []
        currentLayoutSeed = 0
        currentTemplateName = ""
    }
}

// MARK: - Auto-Styled Preview View
struct AutoStyledPreviewView: View {
    let title: String
    @State var linesData: [[LineData]]
    let moods: [Mood]
    let textAlignment: TextAlignment
    @State var templateName: String
    let onRegenerate: () -> Void
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    @State private var currentPageIndex = 0
    @State private var isRegenerating = false
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: background)
            
            VStack {
                // Top Bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(background.textColor)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Preview")
                            .font(.system(size: 18, weight: .medium))
                        Text("Style: \(templateName)")
                            .font(.system(size: 12))
                            .opacity(0.7)
                    }
                    .foregroundColor(background.textColor)
                    
                    Spacer()
                    
                    Button("Post") {
                        onConfirm()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(background.textColor)
                    .padding(.horizontal)
                
                Spacer()
                
                // Content Display
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
                
                // Moods Display
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
                .padding(.bottom, 20)
                
                // Regenerate Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isRegenerating = true
                    }
                    
                    // Regenerate layout
                    let result = TemplateEngine.generateStyledLayout(
                        title: title,
                        content: linesData.map { pageLines in
                            pageLines.map { $0.text }.joined(separator: "\n")
                        }.joined(separator: "\n\n\n"),
                        moods: moods,
                        alignment: textAlignment,
                        seed: nil
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.linesData = result.linesData
                            self.templateName = result.templateName
                            isRegenerating = false
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isRegenerating ? 360 : 0))
                        Text("Try Different Style")
                    }
                    .foregroundColor(background.textColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
                }
                .disabled(isRegenerating)
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

// MARK: - Mood Selection Chip (Reused)
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
