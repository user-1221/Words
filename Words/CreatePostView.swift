import SwiftUI

// MARK: - Create Post View
struct CreatePostView: View {
    @EnvironmentObject var dataController: DataController
    @State private var title = ""
    @State private var pages: [String] = [""]
    @State private var currentPageIndex = 0
    @State private var selectedMoods: Set<Mood> = []
    @State private var selectedAlignment: TextAlignment = .center
    @State private var showingPreview = false
    
    // Auto font size calculation
    private let maxCharactersPerPage = 300
    private let baseFontSize: CGFloat = 24
    private let minFontSize: CGFloat = 14
    private let maxFontSize: CGFloat = 32
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        pages.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) &&
        !selectedMoods.isEmpty &&
        selectedMoods.count <= 3
    }
    
    // Calculate optimal font size based on content
    private func calculateOptimalFontSize(for text: String) -> CGFloat {
        let charCount = text.count
        
        if charCount <= 50 {
            return maxFontSize
        } else if charCount <= 100 {
            return 28
        } else if charCount <= 200 {
            return 20
        } else if charCount <= 300 {
            return 16
        } else {
            return minFontSize
        }
    }
    
    // Get the optimal font size for all pages
    private var optimalFontSize: CGFloat {
        let longestPage = pages.max { $0.count < $1.count } ?? ""
        return calculateOptimalFontSize(for: longestPage)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // User's background (now supports video)
                PersistentVideoBackgroundView(backgroundType: background)
                
                VStack(spacing: 0) {
                    // Content Input
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
                            
                            // Page Navigation
                            HStack {
                                Text("Page \(currentPageIndex + 1) of \(pages.count)")
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
                                            .foregroundColor(background.textColor)
                                    }
                                    
                                    Button(action: addNewPage) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(background.textColor)
                                    }
                                }
                            }
                            
                            // Text Editor for current page
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Your Words")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(background.textColor)
                                    
                                    Spacer()
                                    
                                    Text("\(pages[currentPageIndex].count)/\(maxCharactersPerPage)")
                                        .font(.system(size: 14))
                                        .foregroundColor(pages[currentPageIndex].count > maxCharactersPerPage ? .red : background.textColor.opacity(0.7))
                                }
                                
                                ZStack(alignment: .topLeading) {
                                    if pages[currentPageIndex].isEmpty {
                                        Text("Share your thoughts, feelings, or reflections...")
                                            .foregroundColor(background.textColor.opacity(0.5))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    
                                    TextEditor(text: $pages[currentPageIndex])
                                        .font(.system(size: optimalFontSize, weight: .light, design: .serif))
                                        .foregroundColor(background.textColor)
                                        .multilineTextAlignment(selectedAlignment.swiftUIAlignment)
                                        .frame(minHeight: 200)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .onChange(of: pages[currentPageIndex]) { oldValue, newValue in
                                            // Limit characters per page
                                            if newValue.count > maxCharactersPerPage {
                                                pages[currentPageIndex] = String(newValue.prefix(maxCharactersPerPage))
                                            }
                                        }
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                
                                // Character limit warning
                                if pages[currentPageIndex].count > maxCharactersPerPage - 50 {
                                    Text("Approaching character limit. Consider adding a new page.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 4)
                                }
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
                                            Image(systemName: alignment.icon)
                                                .font(.system(size: 20))
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
                            
                            // Auto Font Size Info
                            HStack {
                                Image(systemName: "textformat.size")
                                    .foregroundColor(background.textColor.opacity(0.7))
                                Text("Font size adjusts automatically based on content length")
                                    .font(.system(size: 14))
                                    .foregroundColor(background.textColor.opacity(0.7))
                            }
                            .padding(.horizontal, 4)
                            
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
        .sheet(isPresented: $showingPreview) {
            PreviewPostView(
                title: title,
                pages: pages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                moods: Array(selectedMoods),
                fontSize: optimalFontSize,
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
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
        }
    }
    
    private func addNewPage() {
        pages.append("")
        currentPageIndex = pages.count - 1
    }
    
    private func createPost() {
        guard canPost else { return }
        
        let nonEmptyPages = pages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        dataController.createPost(
            title: title,
            content: nonEmptyPages,
            moods: Array(selectedMoods),
            fontSize: optimalFontSize,
            textAlignment: selectedAlignment
        )
        
        // Reset form
        title = ""
        pages = [""]
        currentPageIndex = 0
        selectedMoods = []
        selectedAlignment = .center
    }
}

// MARK: - Mood Selection Chip Component (unchanged)
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

// MARK: - Preview Post View (Updated)
struct PreviewPostView: View {
    let title: String
    let pages: [String]
    let moods: [Mood]
    let fontSize: CGFloat
    let textAlignment: TextAlignment
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
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
                
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(background.textColor)
                    .padding(.horizontal)
                
                Spacer()
                
                // Multi-page content
                if pages.count > 1 {
                    TabView {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            ScrollView {
                                Text(page)
                                    .font(.system(size: fontSize, weight: .light, design: .serif))
                                    .foregroundColor(background.textColor)
                                    .multilineTextAlignment(textAlignment.swiftUIAlignment)
                                    .padding(40)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                } else {
                    ScrollView {
                        Text(pages.first ?? "")
                            .font(.system(size: fontSize, weight: .light, design: .serif))
                            .foregroundColor(background.textColor)
                            .multilineTextAlignment(textAlignment.swiftUIAlignment)
                            .padding(40)
                    }
                }
                
                Spacer()
                
                // Mood indicators
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
}
