import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingSendAppreciation = false
    @State private var selectedPost: WordPost?
    @State private var currentIndex = 0
    @State private var currentPageIndex: [String: Int] = [:]

    var userBackground: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var currentPost: WordPost? {
        guard currentIndex < dataController.posts.count else { return nil }
        return dataController.posts[currentIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            if dataController.isLoading && dataController.posts.isEmpty {
                LoadingView()
            } else if dataController.posts.isEmpty {
                EmptyHomeView()
            } else {
                ZStack {
                    PersistentVideoBackgroundView(backgroundType: userBackground)

                    ZStack {
                        ForEach(Array(dataController.posts.enumerated()), id: \.element.id) { index, post in
                            LayoutBasedPostContent(
                                post: post,
                                background: userBackground,
                                currentPageIndex: binding(for: post),
                                geometry: geometry,
                                onAppreciate: {
                                    selectedPost = post
                                    showingSendAppreciation = true
                                }
                            )
                            .opacity(index == currentIndex ? 1 : 0)
                            .scaleEffect(index == currentIndex ? 1 : 0.95)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                        }
                    }

                    if dataController.posts.count > 1 {
                        VStack {
                            Spacer()
                            HStack(spacing: 8) {
                                ForEach(0..<min(dataController.posts.count, 10), id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.bottom, 50)
                        }
                    }
                }
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            handleSwipe(value: value)
                        }
                )
            }
        }
        .sheet(isPresented: $showingSendAppreciation) {
            if let post = selectedPost {
                SendAppreciationView(post: post)
            }
        }
    }
    
    private func binding(for post: WordPost) -> Binding<Int> {
        let postId = post.id ?? ""
        return Binding(
            get: { currentPageIndex[postId] ?? 0 },
            set: { currentPageIndex[postId] = $0 }
        )
    }
    
    private func handleSwipe(value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        let threshold: CGFloat = 50
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if abs(horizontalAmount) > abs(verticalAmount) {
                if let post = currentPost, post.structuredContent.count > 1 {
                    let postId = post.id ?? ""
                    let currentPage = currentPageIndex[postId] ?? 0
                    
                    if horizontalAmount < -threshold {
                        if currentPage < post.structuredContent.count - 1 {
                            currentPageIndex[postId] = currentPage + 1
                        }
                    } else if horizontalAmount > threshold {
                        if currentPage > 0 {
                            currentPageIndex[postId] = currentPage - 1
                        }
                    }
                }
            } else {
                if verticalAmount < -threshold {
                    currentIndex = min(currentIndex + 1, dataController.posts.count - 1)
                } else if verticalAmount > threshold {
                    currentIndex = max(currentIndex - 1, 0)
                }
            }
        }
    }
}

// MARK: - Layout Based Post Content
struct LayoutBasedPostContent: View {
    let post: WordPost
    let background: BackgroundType
    @Binding var currentPageIndex: Int
    let geometry: GeometryProxy
    let onAppreciate: () -> Void
    @EnvironmentObject var dataController: DataController
    
    // Process post dynamically based on viewer's background
    var processedPost: (pages: [[LineData]], layout: TextBoxLayout) {
        DynamicLayoutProcessor.processPostForViewing(
            post: post,
            viewerBackground: background,
            geometry: geometry
        )
    }

    var hasUserAppreciated: Bool {
        guard let postId = post.id else { return false }
        return dataController.hasUserAppreciatedPost(postId: postId)
    }

    var body: some View {
        ZStack {
            // Content positioned according to viewer's layout
            let structuredContent = processedPost.pages
            let layout = processedPost.layout
            
            if structuredContent.count > 1 {
                ForEach(Array(structuredContent.enumerated()), id: \.offset) { pageIndex, pageLines in
                    PostPageContent(
                        title: pageIndex == 0 ? post.title : nil,
                        lines: pageLines,
                        alignment: post.textAlignment,
                        textColor: background.textColor,
                        layout: layout,
                        geometry: geometry,
                        moods: post.moods
                    )
                    .opacity(pageIndex == currentPageIndex ? 1 : 0)
                    .scaleEffect(pageIndex == currentPageIndex ? 1 : 0.9)
                    .animation(.easeInOut(duration: 0.3), value: currentPageIndex)
                }
                
                // Page indicators
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<structuredContent.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPageIndex ? background.textColor : background.textColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 120)
                }
            } else if let firstPage = structuredContent.first {
                PostPageContent(
                    title: post.title,
                    lines: firstPage,
                    alignment: post.textAlignment,
                    textColor: background.textColor,
                    layout: layout,
                    geometry: geometry,
                    moods: post.moods
                )
            }
            
            // Bottom controls
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(background.textColor.opacity(0.7))

                        if post.structuredContent.count > 1 {
                            Text("Page \(currentPageIndex + 1) of \(post.structuredContent.count)")
                                .font(.system(size: 11))
                                .foregroundColor(background.textColor.opacity(0.5))
                        }
                    }

                    Spacer()

                    if post.authorId != dataController.currentUserId {
                        Button(action: hasUserAppreciated ? {} : onAppreciate) {
                            VStack(spacing: 4) {
                                Image(systemName: hasUserAppreciated ? "heart.fill" : "heart")
                                    .font(.system(size: 28))
                                    .foregroundColor(hasUserAppreciated ? .pink : background.textColor)

                                if post.appreciationCount > 0 {
                                    Text("\(post.appreciationCount)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(background.textColor)
                                }
                            }
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(25)
                        }
                        .disabled(hasUserAppreciated)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Post Page Content
struct PostPageContent: View {
    let title: String?
    let lines: [LineData]
    let alignment: TextAlignment
    let textColor: Color
    let layout: TextBoxLayout
    let geometry: GeometryProxy
    let moods: [Mood]
    
    var body: some View {
        let frame = layout.frame(in: geometry)
        
        ZStack {
            // Content container
            VStack(alignment: textAlignmentToHStack(alignment), spacing: 8) {
                if let title = title {
                    Text(title)
                        .font(.system(size: 26, weight: .semibold, design: .serif))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(alignment.swiftUIAlignment)
                        .padding(.bottom, 8)
                }
                
                if alignment.isVertical {
                    ScrollView(.horizontal, showsIndicators: false) {
                        VerticalLinesView(
                            lines: lines,
                            textColor: textColor,
                            maxHeight: frame.height * 0.8
                        )
                    }
                } else {
                    //ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: textAlignmentToHStack(alignment), spacing: 6) {
                            ForEach(Array(lines.enumerated()), id: \.offset) { _, lineData in
                                if lineData.text.isEmpty {
                                    // Preserve empty lines as spacing
                                    Text(" ")
                                        .font(.system(size: lineData.fontSize))
                                } else {
                                    Text(lineData.text)
                                        .font(.system(size: lineData.fontSize, weight: .light, design: .serif))
                                        .foregroundColor(textColor)
                                        .multilineTextAlignment(alignment.swiftUIAlignment)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    //}
                }
                
                // Mood tags at bottom of text box
                if !moods.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(moods.prefix(3), id: \.self) { mood in
                            HStack(spacing: 4) {
                                Text(mood.icon)
                                    .font(.system(size: 12))
                                Text(mood.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.2))
                            .foregroundColor(textColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .frame(width: frame.width, height: frame.height)
        }
        .position(x: frame.midX, y: frame.midY)
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

// MARK: - Loading View
struct LoadingView: View {
    @EnvironmentObject var dataController: DataController

    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(dataController.userPreferences.selectedBackground.textColor)

                Text("Loading words...")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
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
