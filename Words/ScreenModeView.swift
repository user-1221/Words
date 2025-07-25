import SwiftUI

// MARK: - Screen Mode View
struct ScreenModeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isActive = false
    @State private var selectedMoods: Set<Mood> = []
    @State private var scrollSpeed: Double = 5.0
    @State private var fontSize: CGFloat = 24
    @State private var currentPostIndex = 0
    @State private var timer: Timer?
    
    var filteredPosts: [WordPost] {
        let posts = dataController.getPostsByMoods(selectedMoods)
        return posts.isEmpty ? dataController.posts : posts
    }
    
    var body: some View {
        NavigationView {
            if isActive {
                activeScreenMode
            } else {
                setupScreenMode
            }
        }
    }
    
    // MARK: - Setup View
    var setupScreenMode: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "tv")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Screen Mode")
                    .font(.system(size: 32, weight: .light, design: .serif))
                
                Text("Transform your screen into a peaceful display of words")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Mood Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter by Mood")
                        .font(.system(size: 18, weight: .medium))
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            MoodToggleChip(
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
                
                // Scroll Speed
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scroll Speed")
                        .font(.system(size: 18, weight: .medium))
                    
                    HStack {
                        Text("Slow")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $scrollSpeed, in: 2...10, step: 1)
                            .accentColor(.blue)
                        
                        Text("Fast")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(Int(scrollSpeed)) seconds per word")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Font Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size")
                        .font(.system(size: 18, weight: .medium))
                    
                    HStack {
                        Text("Small")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $fontSize, in: 18...36, step: 2)
                            .accentColor(.blue)
                        
                        Text("Large")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Size: \(Int(fontSize))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            // Start Button
            Button("Start Screen Mode") {
                startScreenMode()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(filteredPosts.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(filteredPosts.isEmpty)
            
            if filteredPosts.isEmpty {
                Text("No words available with selected filters")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("Screen Mode")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Active Screen Mode
    var activeScreenMode: some View {
        ZStack {
            // Background
            if !filteredPosts.isEmpty {
                filteredPosts[currentPostIndex].backgroundType.gradient
                    .ignoresSafeArea()
            }
            
            VStack {
                // Control Bar
                HStack {
                    Button("Stop") {
                        stopScreenMode()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    if !filteredPosts.isEmpty {
                        Text("\(currentPostIndex + 1) / \(filteredPosts.count)")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(20)
                    }
                }
                .padding()
                
                Spacer()
                
                // Current Post
                if !filteredPosts.isEmpty {
                    ScrollView {
                        Text(filteredPosts[currentPostIndex].content)
                            .font(.system(size: fontSize, weight: .light, design: .serif))
                            .foregroundColor(filteredPosts[currentPostIndex].backgroundType.textColor)
                            .multilineTextAlignment(.center)
                            .padding(40)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
                
                // Mood Indicators
                if !filteredPosts.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(filteredPosts[currentPostIndex].moods, id: \.self) { mood in
                            Text("\(mood.icon)")
                                .font(.system(size: 20))
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Helper Methods
    private func startScreenMode() {
        guard !filteredPosts.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            isActive = true
            currentPostIndex = 0
        }
    }
    
    private func stopScreenMode() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isActive = false
        }
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: scrollSpeed, repeats: true) { _ in
            nextPost()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func nextPost() {
        guard !filteredPosts.isEmpty else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            currentPostIndex = (currentPostIndex + 1) % filteredPosts.count
        }
    }
}

// MARK: - Mood Toggle Chip
struct MoodToggleChip: View {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}//
//  ScreenModeView.swift
//  Words
//
//  Created by Hiro on 2025/07/24.
//

