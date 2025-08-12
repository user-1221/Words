import SwiftUI

// MARK: - Create Post View (Simple - No Layout)
struct CreatePostView: View {
    @EnvironmentObject var dataController: DataController
    @State private var title = ""
    @State private var content = ""
    @State private var selectedMoods: Set<Mood> = []
    @State private var selectedAlignment: TextAlignment = .center
    @State private var fontSize: CGFloat = 20
    @State private var showingPreview = false
    
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
                                
                                Text("Write freely. Each reader will see it their way.")
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
                                    
                                    Text("• Use line breaks for visual rhythm")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                    
                                    Text("• Empty lines create breathing space")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                    
                                    Text("• Each viewer sees it differently based on their background")
                                        .font(.system(size: 12))
                                        .foregroundColor(background.textColor.opacity(0.6))
                                }
                                .padding(.horizontal, 8)
                            }
                            
                            // Font Size Slider
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Base Font Size: \(Int(fontSize))")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(background.textColor)
                                
                                Slider(value: $fontSize, in: 14...32, step: 1)
                                    .accentColor(background.textColor)
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
                        .background(canPost ? Color.white.opacity(0.8) : Color.gray.opacity(0.3))
                        .foregroundColor(canPost ? background.textColor : background.textColor.opacity(0.5))
                        .cornerRadius(12)
                        .disabled(!canPost)
                        
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
            SimplePreviewView(
                title: title,
                content: content,
                moods: Array(selectedMoods),
                fontSize: fontSize,
                textAlignment: selectedAlignment,
                background: background,
                onConfirm: {
                    showingPreview = false
                    createPost()
                }
            )
        }
    }
    
    // MARK: - Create Post (Simple)
    private func createPost() {
        guard canPost else { return }
        
        // Just save the raw content - viewers will format it based on their background
        dataController.createPost(
            title: title,
            content: [content], // Save as single page
            moods: Array(selectedMoods),
            fontSize: fontSize,
            textAlignment: selectedAlignment
        )
        
        // Reset form
        title = ""
        content = ""
        selectedMoods = []
        selectedAlignment = .center
        fontSize = 20
    }
}

// MARK: - Simple Preview View
struct SimplePreviewView: View {
    let title: String
    let content: String
    let moods: [Mood]
    let fontSize: CGFloat
    let textAlignment: TextAlignment
    let background: BackgroundType
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var currentPageIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
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
                        
                        Text("Preview")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(background.textColor)
                        
                        Spacer()
                        
                        Button("Post") {
                            onConfirm()
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Note about dynamic layout
                    Text("Note: Each viewer will see this differently based on their background")
                        .font(.system(size: 12))
                        .foregroundColor(background.textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Simple preview of content
                    let layout = BackgroundLayoutConfig.getLayout(for: background)
                    let frame = layout.frame(in: geometry)
                    
                    ScrollView {
                        VStack(alignment: textAlignmentToHStack(textAlignment), spacing: 8) {
                            Text(title)
                                .font(.system(size: fontSize + 4, weight: .semibold, design: .serif))
                                .foregroundColor(background.textColor)
                                .multilineTextAlignment(textAlignment.swiftUIAlignment)
                                .padding(.bottom, 8)
                            
                            Text(content)
                                .font(.system(size: fontSize, weight: .light, design: .serif))
                                .foregroundColor(background.textColor)
                                .multilineTextAlignment(textAlignment.swiftUIAlignment)
                        }
                        .padding()
                        .frame(width: frame.width, height: frame.height)
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .position(x: frame.midX, y: frame.midY)
                    
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
                    .padding(.bottom, 40)
                }
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
