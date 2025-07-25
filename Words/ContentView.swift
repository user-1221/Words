import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var selectedTab = 0
    
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
        .alert("Error", isPresented: .constant(dataController.errorMessage != nil)) {
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Text("Words")
                    .font(.system(size: 48, weight: .thin, design: .serif))
                    .padding(.top, 60)
                
                Text("A space for reflection and resonance")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 20) {
                    if dataController.isLoading {
                        ProgressView("Connecting...")
                            .font(.system(size: 16, weight: .light))
                    } else {
                        Text("Welcome to your sanctuary of words")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !dataController.posts.isEmpty {
                            Text("\(dataController.posts.count) words shared")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
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
                
                Spacer()
                
                ScrollView {
                    Text(post.content)
                        .font(.system(size: post.fontSize, weight: .light, design: .serif))
                        .foregroundColor(post.backgroundType.textColor)
                        .multilineTextAlignment(.center)
                        .padding(40)
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
