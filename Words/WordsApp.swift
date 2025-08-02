import SwiftUI
import FirebaseCore

// Add this to control orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct WordsApp: App {
    @StateObject private var dataController = DataController()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        FirebaseApp.configure()
        
        // Preload video backgrounds in the background
        DispatchQueue.global(qos: .background).async {
            // Load the default background first if it's a video
            if let defaultBackground = UserDefaults.standard.data(forKey: "userPreferences"),
               let preferences = try? JSONDecoder().decode(UserPreferences.self, from: defaultBackground),
               preferences.selectedBackground.isVideo {
                VideoBackgroundManager.shared.loadVideo(for: preferences.selectedBackground)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
        }
    }
}
