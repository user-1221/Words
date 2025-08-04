import SwiftUI

// MARK: - Home View
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
            if dataController.isLoading && dataController.posts.isEmpty {
                LoadingView()
            } else if dataController.posts.isEmpty {
                EmptyHomeView()
            } else {
                ZStack {
                    PersistentVideoBackgroundView(backgroundType: userBackground)

                    ZStack {
                        ForEach(Array(dataController.posts.enumerated()), id: \.element.id) { index, post in
                            FullScreenPostContent(
                                post: post,
                                background: userBackground,
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

                    Color.clear
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if abs(value.translation.height) > abs(value.translation.width) {
                                        dragOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    if abs(value.translation.height) > abs(value.translation.width) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if value.translation.height < -threshold {
                                                currentIndex = min(currentIndex + 1, dataController.posts.count - 1)
                                            } else if value.translation.height > threshold {
                                                currentIndex = max(currentIndex - 1, 0)
                                            }
                                            dragOffset = 0
                                        }
                                    } else {
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

// MARK: - Full Screen Post Content
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
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

                Text(post.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(background.textColor)
                    .lineLimit(2)
            }
            .padding(.horizontal)
            .padding(.top, 60)

            Spacer()

            if post.content.count > 1 {
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(post.content.enumerated()), id: \.offset) { index, page in
                        ScrollView {
                            Text(page)
                                .font(.system(size: post.fontSize, weight: .light, design: .serif))
                                .foregroundColor(background.textColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 20)
                                .frame(minHeight: 200)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
            } else {
                ScrollView {
                    Text(post.content.first ?? "")
                        .font(.system(size: post.fontSize, weight: .light, design: .serif))
                        .foregroundColor(background.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        .frame(minHeight: 200)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
            }

            Spacer()

            HStack(alignment: .bottom, spacing: 20) {
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

                VStack(spacing: 20) {
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
