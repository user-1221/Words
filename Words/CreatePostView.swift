import SwiftUI

import SwiftUI

// MARK: - Create Post View
struct CreatePostView: View {
    @EnvironmentObject var dataController: DataController
    @State private var title = ""
    @State private var pages: [String] = [""]
    @State private var currentPageIndex = 0
    @State private var selectedMoods: Set<Mood> = []
    @State private var selectedBackground: WordPost.BackgroundType = .paper
    @State private var fontSize: CGFloat = 20
    @State private var showingPreview = false
    
    var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        pages.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) &&
        !selectedMoods.isEmpty &&
        selectedMoods.count <= 3
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content Input
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 18, weight: .medium))
                            
                            TextField("Give your words a title...", text: $title)
                                .font(.system(size: 20, weight: .regular))
                                .padding()
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Page Navigation
                        HStack {
                            Text("Page \(currentPageIndex + 1) of \(pages.count)")
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: previousPage) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(currentPageIndex > 0 ? .blue : .gray)
                                }
                                .disabled(currentPageIndex == 0)
                                
                                Button(action: nextPage) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.blue)
                                }
                                
                                Button(action: addNewPage) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        // Text Editor for current page
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Words")
                                .font(.system(size: 18, weight: .medium))
                            
                            ZStack(alignment: .topLeading) {
                                if pages[currentPageIndex].isEmpty {
                                    Text("Share your thoughts, feelings, or reflections...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                
                                TextEditor(text: $pages[currentPageIndex])
                                    .font(.system(size: fontSize, weight: .light, design: .serif))
                                    .frame(minHeight: 200)
                                    .background(Color.clear)
                            }
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedBackground.gradient.opacity(0.5), lineWidth: 2)
                            )
                        }
                        
                        // Font Size Slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Font Size: \(Int(fontSize))")
                                .font(.system(size: 16, weight: .medium))
                            
                            Slider(value: $fontSize, in: 14...32, step: 2)
                                .accentColor(.blue)
                        }
                        
                        // Background Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Background")
                                .font(.system(size: 16, weight: .medium))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(WordPost.BackgroundType.allCases, id: \.self) { background in
                                        BackgroundChip(
                                            background: background,
                                            isSelected: selectedBackground == background
                                        ) {
                                            selectedBackground = background
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        // Mood Selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Moods")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Spacer()
                                
                                Text("\(selectedMoods.count)/3")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
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
                    .background(Color.secondary.opacity(0.2))
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
                .background(Color(UIColor.systemGray6))
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingPreview) {
            PreviewPostView(
                title: title,
                pages: pages.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                background: selectedBackground,
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
            backgroundType: selectedBackground,
            moods: Array(selectedMoods),
            fontSize: fontSize
        )
        
        // Reset form
        title = ""
        pages = [""]
        currentPageIndex = 0
        selectedMoods = []
        selectedBackground = .paper
        fontSize = 20
    }
}
// MARK: - Background Chip Component
struct BackgroundChip: View {
    let background: WordPost.BackgroundType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(background.gradient)
                    .frame(width: 60, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                Text(background.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
        }
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
                isDisabled ? Color.gray.opacity(0.3) : Color(UIColor.systemGray5)
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
    let content: String
    let background: WordPost.BackgroundType
    let moods: [Mood]
    let fontSize: CGFloat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            background.gradient
                .ignoresSafeArea()
            
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
                        .frame(width: 44) // Balance the "Done" button
                }
                .padding()
                
                Spacer()
                
                ScrollView {
                    Text(content)
                        .font(.system(size: fontSize, weight: .light, design: .serif))
                        .foregroundColor(background.textColor)
                        .multilineTextAlignment(.center)
                        .padding(40)
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
