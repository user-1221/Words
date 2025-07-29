import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var selectedTab = 0
    @State private var showingError = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            SearchModeView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            CreatePostView()
                .tabItem {
                    Label("Create", systemImage: "square.and.pencil")
                }
                .tag(2)
            
            ScreenModeView()
                .tabItem {
                    Label("Screen", systemImage: "tv")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .badge(dataController.unreadAppreciationCount > 0 ? "\(dataController.unreadAppreciationCount)" : nil)
                .tag(4)
        }
        .onReceive(dataController.$errorMessage) { errorMessage in
            showingError = errorMessage != nil
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                dataController.clearError()
            }
        } message: {
            if let errorMessage = dataController.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingSendAppreciation = false
    @State private var selectedPost: WordPost?
    
    var body: some View {
        GeometryReader { geometry in
            if dataController.isLoading {
                LoadingView()
            } else if dataController.posts.isEmpty {
                EmptyHomeView()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(dataController.posts) { post in
                            FullScreenPostView(
                                post: post,
                                onAppreciate: {
                                    selectedPost = post
                                    showingSendAppreciation = true
                                }
                            )
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        }
                    }
                }
                .ignoresSafeArea()
                .scrollTargetBehavior(.paging)
            }
        }
        .sheet(isPresented: $showingSendAppreciation) {
            if let post = selectedPost {
                SendAppreciationView(post: post)
            }
        }
    }
}

// MARK: - Full Screen Post View (Reels-style)
struct FullScreenPostView: View {
    let post: WordPost
    let onAppreciate: () -> Void
    @EnvironmentObject var dataController: DataController
    
    var hasUserAppreciated: Bool {
        guard let postId = post.id else { return false }
        return dataController.hasUserAppreciatedPost(postId: postId)
    }
    
    var body: some View {
        ZStack {
            // Background
            post.backgroundType.gradient
                .ignoresSafeArea()
            
            // Content
            VStack {
                // Top bar with metadata
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Moods
                        HStack(spacing: 8) {
                            ForEach(post.moods.prefix(3), id: \.self) { mood in
                                HStack(spacing: 4) {
                                    Text(mood.icon)
                                    Text(mood.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.2))
                                .foregroundColor(post.backgroundType.textColor)
                                .cornerRadius(15)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Title display
                    Text(post.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(post.backgroundType.textColor.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                // Main content - centered
                if post.content.count > 1 {
                    TabView {
                        ForEach(Array(post.content.enumerated()), id: \.offset) { index, page in
                            ScrollView {
                                Text(page)
                                    .font(.system(size: post.fontSize, weight: .light, design: .serif))
                                    .foregroundColor(post.backgroundType.textColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                } else {
                    ScrollView {
                        Text(post.content.first ?? "")
                            .font(.system(size: post.fontSize, weight: .light, design: .serif))
                            .foregroundColor(post.backgroundType.textColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                }
                
                Spacer()
                
                // Bottom interaction area
                HStack(alignment: .bottom, spacing: 20) {
                    // Left side - post info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(post.backgroundType.textColor.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Right side - actions
                    VStack(spacing: 20) {
                        // Appreciation button
                        if post.authorId != dataController.currentUserId {
                            Button(action: hasUserAppreciated ? {} : onAppreciate) {
                                VStack(spacing: 4) {
                                    Image(systemName: hasUserAppreciated ? "heart.fill" : "heart")
                                        .font(.system(size: 28))
                                        .foregroundColor(hasUserAppreciated ? .pink : .white)
                                    
                                    if post.appreciationCount > 0 {
                                        Text("\(post.appreciationCount)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(25)
                            }
                            .disabled(hasUserAppreciated)
                        }
                        
                        // Share button (placeholder for future)
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(25)
                        }
                        .disabled(true)
                        .opacity(0.5)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            // Swipe indicator (subtle)
            VStack {
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(post.backgroundType.textColor.opacity(0.3))
                            .frame(width: 20, height: 1)
                    }
                }
                .padding(.bottom, 120)
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "E0E0E0"), Color(hex: "F5F5F5")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.gray)
                
                Text("Loading words...")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Empty Home View
struct EmptyHomeView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F5F5DC"), Color(hex: "E8E8D5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "text.quote")
                    .font(.system(size: 80))
                    .foregroundColor(.black.opacity(0.2))
                
                Text("No words yet")
                    .font(.system(size: 36, weight: .thin, design: .serif))
                    .foregroundColor(.black.opacity(0.8))
                
                Text("Be the first to share\nyour thoughts")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.black.opacity(0.4))
                    
                    Text("Swipe up when words appear")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.4))
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Full Post View
struct FullPostView: View {
    let post: WordPost
    var showAppreciationButton: Bool = true
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    @State private var showingSendAppreciation = false
    
    var body: some View {
        ZStack {
            post.backgroundType.gradient
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(post.backgroundType.textColor)
                    .padding()
                }
                
                // Title
                Text(post.title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(post.backgroundType.textColor)
                    .padding(.horizontal)
                
                Spacer()
                
                // Multi-page content
                if post.content.count > 1 {
                    TabView {
                        ForEach(Array(post.content.enumerated()), id: \.offset) { index, page in
                            ScrollView {
                                Text(page)
                                    .font(.system(size: post.fontSize, weight: .light, design: .serif))
                                    .foregroundColor(post.backgroundType.textColor)
                                    .multilineTextAlignment(.center)
                                    .padding(40)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                } else {
                    ScrollView {
                        Text(post.content.first ?? "")
                            .font(.system(size: post.fontSize, weight: .light, design: .serif))
                            .foregroundColor(post.backgroundType.textColor)
                            .multilineTextAlignment(.center)
                            .padding(40)
                    }
                }
                
                Spacer()
                
                if showAppreciationButton && post.authorId != dataController.currentUserId {
                    Button(action: { showingSendAppreciation = true }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Send Appreciation")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(25)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingSendAppreciation) {
            SendAppreciationView(post: post)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataController())
}
