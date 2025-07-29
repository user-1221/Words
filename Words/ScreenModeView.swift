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
                            StaggeredGrid(columns: 2, spacing: 12) {
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

// MARK: - Staggered Grid Layout
struct StaggeredGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let content: () -> Content
    
    init(columns: Int, spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { column in
                VStack(spacing: spacing) {
                    ForEach(Array(Mirror(reflecting: content()).children.enumerated()), id: \.offset) { index, child in
                        if index % columns == column {
                            AnyView(child.value as! any View)
                        }
                    }
                }
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
        let baseHeight: CGFloat = 180
        let variations: [CGFloat] = [0, 40, 80, 120]
        let index = abs(post.title.hashValue) % variations.count
        return baseHeight + variations[index]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area with background
            ZStack(alignment: .bottomLeading) {
                post.backgroundType.gradient
                
                // Gradient overlay for better text readability
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // Title prominently displayed
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    // Mood icons
                    HStack(spacing: 6) {
                        ForEach(post.moods.prefix(2), id: \.self) { mood in
                            Text(mood.icon)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding()
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
