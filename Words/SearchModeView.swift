import SwiftUI

// MARK: - Search Mode View
struct SearchModeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var selectedMoods: Set<Mood> = []
    @State private var showingFullPost = false
    @State private var selectedPost: WordPost?
    
    var filteredPosts: [WordPost] {
        dataController.getPostsByMoods(selectedMoods)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Mood Filter Bar (auto-sized)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
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
                        .padding(.horizontal)
                        .padding(.vertical, 4) // Shrink height
                        .frame(height: geo.size.height * 0.2)
                    }
                    .background(Color(UIColor.systemGray6))
                    
                    // Posts List fills the rest
                    Group {
                        if filteredPosts.isEmpty {
                            EmptySearchView()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredPosts) { post in
                                        PostCard(post: post) {
                                            selectedPost = post
                                            showingFullPost = true
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxHeight: .infinity)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Search Words")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingFullPost) {
            if let post = selectedPost {
                FullPostView(post: post)
            }
        }

        .sheet(isPresented: $showingFullPost) {
            if let post = selectedPost {
                FullPostView(post: post)
            }
        }
    }
}
// MARK: - Mood Chip Component
struct MoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(mood.icon)
                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Post Card Component
struct PostCard: View {
    let post: WordPost
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content preview
            Text(post.content)
                .font(.system(size: 16, weight: .light))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            // Metadata
            HStack {
                // Moods
                HStack(spacing: 6) {
                    ForEach(post.moods.prefix(3), id: \.self) { mood in
                        Text("\(mood.icon)")
                            .font(.system(size: 12))
                    }
                }
                
                Spacer()
                
                // Appreciation count
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                    Text("\(post.appreciationCount)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.pink)
            }
            
            // Date
            Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(post.backgroundType.gradient.opacity(0.3))
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No words found")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary)
            
            Text("Try adjusting your mood filters\nor check back later")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
