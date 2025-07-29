import SwiftUI

// MARK: - Screen Mode View
struct ScreenModeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var selectedMoods: Set<Mood> = []
    @State private var scrollSpeed: Double = 5
    @State private var fontSize: CGFloat = 24
    @State private var isActive = false
    @State private var currentPostIndex = 0
    @State private var timer: Timer?
    
    var filteredPosts: [WordPost] {
        dataController.getPostsByMoods(selectedMoods)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !isActive {
                    // Settings View
                    ScrollView {
                        VStack(spacing: 24) {
                            // Instructions
                            VStack(spacing: 8) {
                                Image(systemName: "tv")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                                
                                Text("Screen Mode")
                                    .font(.system(size: 28, weight: .semibold))
                                
                                Text("Display words ambiently while you work, study, or relax")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 40)
                            
                            // Mood Filter
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Moods")
                                    .font(.system(size: 20, weight: .medium))
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(Mood.allCases, id: \.self) { mood in
                                        ScreenMoodChip(
                                            mood: mood,
                                            isSelected: selectedMoods.contains(mood)
                                        ) {
                                            if selectedMoods.contains(mood) {
                                                selectedMoods.remove(mood)
                                            } else {
                                                selectedMoods.insert(mood)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Settings
                            VStack(spacing: 20) {
                                // Scroll Speed
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Transition Speed: \(Int(scrollSpeed))s")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Slider(value: $scrollSpeed, in: 3...15, step: 1)
                                        .accentColor(.blue)
                                }
                                
                                // Font Size
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Font Size: \(Int(fontSize))")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Slider(value: $fontSize, in: 18...36, step: 2)
                                        .accentColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Start Button
                            Button(action: startScreenMode) {
                                Text("Start Screen Mode")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(filteredPosts.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(12)
                            }
                            .disabled(filteredPosts.isEmpty)
                            .padding(.horizontal)
                            
                            if filteredPosts.isEmpty {
                                Text("Select at least one mood to start")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                } else {
                    // Active Screen Mode
                    if filteredPosts.isEmpty {
                        EmptyScreenModeView()
                    } else {
                        ZStack {
                            // Current post display
                            if currentPostIndex < filteredPosts.count {
                                let post = filteredPosts[currentPostIndex]
                                
                                post.backgroundType.gradient
                                    .ignoresSafeArea()
                                
                                VStack {
                                    Spacer()
                                    
                                    // Title
                                    Text(post.title)
                                        .font(.system(size: fontSize + 4, weight: .medium, design: .serif))
                                        .foregroundColor(post.backgroundType.textColor)
                                        .padding(.horizontal, 40)
                                        .padding(.bottom, 20)
                                    
                                    // Content with page handling
                                    if post.content.count > 1 {
                                        TabView {
                                            ForEach(Array(post.content.enumerated()), id: \.offset) { index, page in
                                                Text(page)
                                                    .font(.system(size: fontSize, weight: .light, design: .serif))
                                                    .foregroundColor(post.backgroundType.textColor)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, 40)
                                                    .tag(index)
                                            }
                                        }
                                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                                    } else {
                                        Text(post.content.first ?? "")
                                            .font(.system(size: fontSize, weight: .light, design: .serif))
                                            .foregroundColor(post.backgroundType.textColor)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                    
                                    Spacer()
                                    
                                    // Mood indicators
                                    HStack(spacing: 12) {
                                        ForEach(post.moods, id: \.self) { mood in
                                            Text("\(mood.icon) \(mood.rawValue)")
                                                .font(.system(size: 14))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(0.2))
                                                .foregroundColor(post.backgroundType.textColor)
                                                .cornerRadius(15)
                                        }
                                    }
                                    .padding(.bottom, 100)
                                }
                                .transition(.opacity)
                            }
                            
                            // Exit button
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: stopScreenMode) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Color.black.opacity(0.3))
                                            .cornerRadius(20)
                                    }
                                    .padding()
                                }
                                Spacer()
                            }
                        }
                        .onAppear {
                            startTimer()
                        }
                        .onDisappear {
                            stopTimer()
                        }
                    }
                }
            }
            .navigationBarHidden(isActive)
            .navigationTitle(isActive ? "" : "Screen Mode")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func startScreenMode() {
        withAnimation {
            isActive = true
            currentPostIndex = 0
        }
    }
    
    private func stopScreenMode() {
        withAnimation {
            isActive = false
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: scrollSpeed, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1)) {
                currentPostIndex = (currentPostIndex + 1) % filteredPosts.count
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Screen Mode Mood Chip
struct ScreenMoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(mood.icon)
                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Empty Screen Mode View
struct EmptyScreenModeView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "tv.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No words available")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}
