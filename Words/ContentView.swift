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
        .tint(.blue)
        .onReceive(dataController.$errorMessage) { errorMessage in
            showingError = errorMessage != nil
        }
        .alert("Notice", isPresented: $showingError) {
            Button("OK") {
                dataController.clearError()
            }
        } message: {
            if let errorMessage = dataController.errorMessage {
                Text(errorMessage)
            }
        }
        .handleVideoBackgroundLifecycle()
    }
}

#Preview {
    ContentView()
        .environmentObject(DataController())
}
