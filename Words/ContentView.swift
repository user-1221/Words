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
        .onAppear {
            // Set tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
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

// MARK: - Home View with Vertical Scroll and Fade Animation
struct HomeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingSendAppreciation = false
    @State private var selectedPost: WordPost?
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    var userBackground: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        GeometryReader { geometry in
            if dataController.isLoading {
                LoadingView()
            } else if dataController.posts.isEmpty {
                EmptyHomeView()
            } else {
                ZStack {
                    // Background stays constant - using persistent video
                    PersistentVideoBackgroundView(backgroundType: userBackground)
                    
                    // Content with custom vertical paging
                    ZStack {
                        ForEach(Array(dataController.posts.enumerated()), id: \.offset) { index, post in
                            FullScreenPostContent(
                                post: post,
                                background: userBackground,
                                onAppreciate: {
                                    selectedPost = post
                                    showingSendAppreciation = true
                                }
                            )
                            .opacity(index == currentIndex ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5), value: currentIndex)
                        }
                    }
                    
                    // Gesture overlay for vertical scrolling
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.height
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        if value.translation.height < -threshold {
                                            // Swipe up - next post
                                            currentIndex = min(currentIndex + 1, dataController.posts.count - 1)
                                        } else if value.translation.height > threshold {
                                            // Swipe down - previous post
                                            currentIndex = max(currentIndex - 1, 0)
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showingSendAppreciation) {
            if let post = selectedPost {
                SendAppreciationView(post: post)
            }
        }
    }
}

// MARK: - Full Screen Post Content (with horizontal page scroll)
struct FullScreenPostContent: View {
    let post: WordPost
    let background: BackgroundType
    let onAppreciate: () -> Void
    @EnvironmentObject var dataController: DataController
    @State private var currentPageIndex = 0
    
    var hasUserAppreciated: Bool {
        guard let postId = post.id else { return false }
        return dataController.hasUserAppreciatedPost(postId: postId)
    }
    
    var body: some View {
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
                            .foregroundColor(background.textColor)
                            .cornerRadius(15)
                        }
                    }
                    
                    Spacer()
                }
                
                // Title display
                Text(post.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(background.textColor.opacity(0.8))
            }
            .padding(.horizontal)
            .padding(.top, 60)
            
            Spacer()
            
            // Main content - horizontal scroll for pages
            if post.content.count > 1 {
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(post.content.enumerated()), id: \.offset) { index, page in
                        ScrollView {
                            Text(page)
                                .font(.system(size: post.fontSize, weight: .light, design: .serif))
                                .foregroundColor(background.textColor)
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
                        .foregroundColor(background.textColor)
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
                        .foregroundColor(background.textColor.opacity(0.7))
                    
                    if post.content.count > 1 {
                        Text("Page \(currentPageIndex + 1) of \(post.content.count)")
                            .font(.system(size: 11))
                            .foregroundColor(background.textColor.opacity(0.5))
                    }
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
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(dataController.userPreferences.selectedBackground.textColor.opacity(0.6))
                
                Text("Loading words...")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(dataController.userPreferences.selectedBackground.textColor.opacity(0.8))
            }
        }
    }
}

// MARK: - Empty Home View
struct EmptyHomeView: View {
    @EnvironmentObject var dataController: DataController
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: background)
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "text.quote")
                    .font(.system(size: 80))
                    .foregroundColor(background.textColor.opacity(0.2))
                
                Text("No words yet")
                    .font(.system(size: 36, weight: .thin, design: .serif))
                    .foregroundColor(background.textColor.opacity(0.8))
                
                Text("Be the first to share\nyour thoughts")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(background.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(background.textColor.opacity(0.4))
                    
                    Text("Swipe up when words appear")
                        .font(.system(size: 14))
                        .foregroundColor(background.textColor.opacity(0.4))
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
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: background)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(background.textColor)
                    .padding()
                }
                
                // Title
                Text(post.title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(background.textColor)
                    .padding(.horizontal)
                
                Spacer()
                
                // Multi-page content
                if post.content.count > 1 {
                    TabView {
                        ForEach(Array(post.content.enumerated()), id: \.offset) { index, page in
                            ScrollView {
                                Text(page)
                                    .font(.system(size: post.fontSize, weight: .light, design: .serif))
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
                        Text(post.content.first ?? "")
                            .font(.system(size: post.fontSize, weight: .light, design: .serif))
                            .foregroundColor(background.textColor)
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
