import SwiftUI
import WaterfallGrid

// MARK: - Search Mode View
struct SearchModeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var selectedMoods: Set<Mood> = []
    @State private var showingFullPost = false
    @State private var selectedPost: WordPost?
    @State private var showingFilters = false
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var filteredPosts: [WordPost] {
        dataController.getPostsByMoods(selectedMoods)
    }
    
    var body: some View {
        ZStack {
            // User's background - persistent video
            PersistentVideoBackgroundView(backgroundType: background)
                .ignoresSafeArea()
            
            // Content on top
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
                                    .foregroundColor(background.textColor)
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
                                WaterfallGrid(filteredPosts) { post in
                                    InstagramStyleCard(post: post) {
                                        selectedPost = post
                                        showingFullPost = true
                                    }
                                }
                                .gridStyle(
                                    columns: 2,
                                    spacing: 12,
                                    animation: .default
                                )
                                .padding(.horizontal, 12)
                            }
                            .background(Color.clear)
                        }
                    }
                    .background(Color.clear)
                    
                    // Filter overlay
                    if showingFilters {
                        filterOverlay
                    }
                }
                .navigationBarHidden(true)
                .background(Color.clear)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        /*
        .sheet(isPresented: $showingFullPost) {
            if let post = selectedPost {
                FullPostView(post: post)
            }
        }
         */
    }
    
    @ViewBuilder
    private var filterOverlay: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 60)
            
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
            .background(Color.white.opacity(0.95))
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

// MARK: - Instagram Style Card (Unchanged)
struct InstagramStyleCard: View {
    let post: WordPost
    let onTap: () -> Void
    
    // Use displayTitle instead of title
    private var cardHeight: CGFloat {
        let baseHeight: CGFloat = 140
        let variations: [CGFloat] = [0, 20, 40, 60, 80, 100]
        let index = abs(post.title.hashValue) % variations.count
        return baseHeight + variations[index]
    }
    
    private var backgroundGray: Color {
        let shades: [Color] = [
            Color(white: 0.95),
            Color(white: 0.85),
            Color(white: 0.75),
            Color(white: 0.65),
            Color(white: 0.55),
            Color(white: 0.45)
        ]
        let idx = abs(post.title.hashValue) % shades.count
        return shades[idx]
    }
    
    private var textColor: Color {
        (backgroundGray == Color(white: 0.45) || backgroundGray == Color(white: 0.55))
            ? .white
            : .black
    }

    var body: some View {
        ZStack {
            backgroundGray
            Text(post.title.uppercased())
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
        }
        .frame(height: cardHeight)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    @EnvironmentObject var dataController: DataController
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(background.textColor.opacity(0.3))
            Text("No words found")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(background.textColor.opacity(0.8))
            Text("Try adjusting your mood filters\nor wait for new posts")
                .font(.system(size: 16))
                .foregroundColor(background.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}
