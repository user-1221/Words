import SwiftUI
import FirebaseCore

@main
struct WordsApp: App {
    @StateObject private var dataController = DataController()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
        }
    }
}
