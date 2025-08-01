import SwiftUI

// MARK: - Create Post View
struct CreatePostView: View {
    @EnvironmentObject var dataController: DataController
    @State private var title = ""
    @State private var pages: [String] = [""]
    @State private var currentPageIndex = 0
    @State private var selectedMoods: Set<Mood> = []
    @State private var fontSize: CGFloat = 20
    @State private var showingPreview = false
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        pages.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) &&
        !selectedMoods.isEmpty &&
        selectedMoods.count <= 3
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
                                Text("Your Words")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                ZStack(alignment: .topLeading) {
                                    if pages[currentPageIndex].isEmpty {
                                        Text("Share your thoughts, feelings, or reflections...")
                                            .foregroundColor(background.textColor.opacity(0.5))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    
                                    TextEditor(text: $pages[currentPageIndex])
                                        .font(.system(size: fontSize, weight: .light, design: .serif))
                                        .foregroundColor(background.textColor)
                                        .frame(minHeight: 200)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                            }
                            
                            // Font Size Slider
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Font Size: \(Int(fontSize))")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                Slider(value: $fontSize, in: 14...32, step: 2)
                                    .accentColor(background.textColor)
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
        .sheet(isPresented: $showingPreview) {
            PreviewPostView(
                title: title,
                pages: pages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                moods: Array(selectedMoods),
                fontSize: fontSize
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
            fontSize: fontSize
        )
        
        // Reset form
        title = ""
        pages = [""]
        currentPageIndex = 0
        selectedMoods = []
        fontSize = 20
    }
}

// MARK: - Mood Selection Chip Component
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
    let pages: [String]
    let moods: [Mood]
    let fontSize: CGFloat
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
                                    .multilineTextAlignment(.center)
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
                            .multilineTextAlignment(.center)
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
