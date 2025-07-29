import SwiftUI

// MARK: - Search Mode View
struct SearchModeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var selectedMoods: Set<Mood> = []
    @State private var showingFullPost = false
    @State private var selectedPost: WordPost?
    @State private var showingFilters = false
    
    var filteredPosts: [WordPost] {
        dataController.getPostsByMoods(selectedMoods)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Main content
                VStack(spacing: 0) {
                    // Top bar with search icon
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showingFilters.toggle()
                            }
                        }) {
                            Image(systemName: showingFilters ? "xmark" : "magnifyingglass")
                                .font(.system(size: 22))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Posts Grid
                    if filteredPosts.isEmpty {
                        EmptySearchView()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(filteredPosts) { post in
                                    InstagramStyleCard(post: post) {
                                        selectedPost = post
                                        showingFullPost = true
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // Collapsible Filter Bar
                if showingFilters {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 60) // Space for top bar
                        
                        VStack(spacing: 12) {
                            Text("Filter by Mood")
                                .font(.system(size: 16, weight: .semibold))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(Mood.allCases, id: \.self) { mood in
                                    MoodChip(
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
                            
                            if !selectedMoods.isEmpty {
                                Button("Clear All") {
                                    selectedMoods.removeAll()
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    .background(
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    showingFilters = false
                                }
                            }
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFullPost) {
            if let post = selectedPost {
                FullPostView(post: post)
            }
        }
    }
}

// MARK: - Instagram Style Card
struct InstagramStyleCard: View {
    let post: WordPost
    let onTap: () -> Void
    
    // Random heights for staggered effect
    private var cardHeight: CGFloat {
        let baseHeight: CGFloat = 140
        let variations: [CGFloat] = [0, 20, 40, 60, 80, 100]
        let index = abs(post.title.hashValue) % variations.count
        return baseHeight + variations[index]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area with background
            ZStack(alignment: .bottomLeading) {
                // 背景を黒に
                Color.black

                // タイトルを中央に
                Text(post.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // ムードアイコンは左下に
                HStack(spacing: 6) {
                    ForEach(post.moods.prefix(2), id: \.self) { mood in
                        Text(mood.icon)
                            .font(.system(size: 14))
                    }
                }
                .padding(8)
            }
            .frame(height: cardHeight)
            .cornerRadius(12)

            
            // Bottom info bar
            HStack {
                // Page count if multi-page
                if post.content.count > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                        Text("\(post.content.count)")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Appreciation count
                if post.appreciationCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                        Text("\(post.appreciationCount)")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.pink)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture(perform: onTap)
    }
}


// MARK: - Mood Chip
struct MoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.icon)
                    .font(.system(size: 20))
                Text(mood.rawValue)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No words found")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary)
            
            Text("Try adjusting your mood filters\nor wait for new posts")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}
