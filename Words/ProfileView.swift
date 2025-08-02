import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationView {
            ZStack {
                // User's background - persistent video
                PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
                
                List {
                    Section {
                        NavigationLink(destination: AppreciationInboxView()) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                    .frame(width: 30)
                                
                                Text("Appreciation Inbox")
                                
                                Spacer()
                                
                                if dataController.unreadAppreciationCount > 0 {
                                    Text("\(dataController.unreadAppreciationCount)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        
                        NavigationLink(destination: MyWordsView()) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                Text("My Words")
                                
                                Spacer()
                                
                                Text("\(dataController.getMyPosts().count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.8))
                    
                    Section("Settings") {
                        NavigationLink(destination: BackgroundSettingsView()) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                
                                Text("Background Theme")
                                
                                Spacer()
                                
                                Text(dataController.userPreferences.selectedBackground.rawValue)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.gray)
                                    .frame(width: 30)
                                
                                Text("App Settings")
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.8))
                    
                    Section("About") {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Words")
                                    .font(.system(size: 16, weight: .medium))
                                Text("A space for reflection and resonance")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.8))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}

// MARK: - Background Settings View
struct BackgroundSettingsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var isLoadingVideo = false
    @State private var selectedBackground: BackgroundType?
    
    // Separate backgrounds into categories
    let gradientBackgrounds: [BackgroundType] = [.paper, .fog, .sunset, .night, .ocean, .forest, .lavender, .mint]
    let videoBackgrounds: [BackgroundType] = [.rainForest, .northernLights, .oceanWaves, .cloudySky, .fireplace, .snowfall, .cityNight, .galaxySpace]
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
            
            ScrollView {
                VStack(spacing: 30) {
                    Text("Choose Your Background")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                        .padding(.top, 20)
                    
                    Text("This background will be applied to all screens")
                        .font(.system(size: 16))
                        .foregroundColor(dataController.userPreferences.selectedBackground.textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // Gradient Backgrounds Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Colors")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                            ForEach(gradientBackgrounds, id: \.self) { background in
                                BackgroundSelectionCard(
                                    background: background,
                                    isSelected: dataController.userPreferences.selectedBackground == background,
                                    isLoading: false
                                ) {
                                    withAnimation(.spring()) {
                                        dataController.updateBackground(background)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Video Backgrounds Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Video Wallpapers")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                            ForEach(videoBackgrounds, id: \.self) { background in
                                BackgroundSelectionCard(
                                    background: background,
                                    isSelected: dataController.userPreferences.selectedBackground == background,
                                    isLoading: isLoadingVideo && selectedBackground == background
                                ) {
                                    selectVideoBackground(background)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    .padding(.bottom, 40)
                }
            }
            
            // Loading overlay
            if isLoadingVideo {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Loading video background...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
            }
        }
        .navigationTitle("Background Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func selectVideoBackground(_ background: BackgroundType) {
        selectedBackground = background
        isLoadingVideo = true
        
        // Load the video in the manager first
        VideoBackgroundManager.shared.loadVideo(for: background)
        
        // Update after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring()) {
                dataController.updateBackground(background)
                isLoadingVideo = false
            }
        }
    }
}

/*
// MARK: - Background Selection Card
struct BackgroundSelectionCard: View {
    let background: BackgroundType
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if background.isVideo {
                        // Show thumbnail for video backgrounds
                        AsyncImage(url: URL(string: background.thumbnailURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            // Fallback gradient while loading thumbnail
                            background.gradient
                        }
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        
                        // Video indicator overlay
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "video.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    } else {
                        // Regular gradient preview
                        background.gradient
                            .frame(height: 120)
                            .cornerRadius(12)
                    }
                    
                    if isLoading {
                        Color.black.opacity(0.6)
                            .cornerRadius(12)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 3)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                    }
                }
                
                Text(background.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
*/
// MARK: - My Words View (Updated)
struct MyWordsView: View {
    @EnvironmentObject var dataController: DataController
    
    var myPosts: [WordPost] {
        dataController.getMyPosts()
    }
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
            
            VStack {
                if myPosts.isEmpty {
                    EmptyMyWordsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(myPosts) { post in
                                MyWordCard(post: post)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("My Words")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Empty My Words View
struct EmptyMyWordsView: View {
    @EnvironmentObject var dataController: DataController
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 80))
                .foregroundColor(background.textColor.opacity(0.3))
            
            Text("You haven't shared any words yet")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(background.textColor.opacity(0.8))
            
            Text("When you create a post,\nit will appear here")
                .font(.system(size: 16))
                .foregroundColor(background.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - My Word Card
struct MyWordCard: View {
    let post: WordPost
    @State private var showingFullPost = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(post.title)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(1)
            
            // First page preview
            Text(post.content.first ?? "")
                .font(.system(size: 16))
                .lineLimit(3)
                .foregroundColor(.secondary)
            
            HStack {
                // Moods
                HStack(spacing: 8) {
                    ForEach(post.moods, id: \.self) { mood in
                        Text("\(mood.icon) \(mood.rawValue)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
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
            Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .onTapGesture {
            showingFullPost = true
        }
        /*
        .sheet(isPresented: $showingFullPost) {
            FullPostView(post: post, showAppreciationButton: false)
        }
        */
    }
}

// MARK: - Appreciation Inbox View (Updated)
struct AppreciationInboxView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
            
            VStack {
                if dataController.myAppreciations.isEmpty {
                    EmptyAppreciationView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(dataController.myAppreciations) { appreciation in
                                AppreciationCard(appreciation: appreciation)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Appreciation Inbox")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !dataController.myAppreciations.filter({ !$0.isRead }).isEmpty {
                    Button("Mark All Read") {
                        dataController.markAllAppreciationsAsRead()
                    }
                    .font(.system(size: 14))
                }
            }
        }
    }
}

// MARK: - Empty Appreciation View
struct EmptyAppreciationView: View {
    @EnvironmentObject var dataController: DataController
    
    var background: BackgroundType {
        dataController.userPreferences.selectedBackground
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 80))
                .foregroundColor(background.textColor.opacity(0.3))
            
            Text("No appreciations yet")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(background.textColor.opacity(0.8))
            
            Text("When someone appreciates your words,\ntheir messages will appear here")
                .font(.system(size: 16))
                .foregroundColor(background.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Appreciation Card
struct AppreciationCard: View {
    let appreciation: AppreciationMessage
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post snippet
            if let postContent = appreciation.postContent {
                Text("For: \"\(postContent)...\"")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Appreciation message
            Text(appreciation.message)
                .font(.system(size: 16))
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(appreciation.sentAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !appreciation.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appreciation.isRead ? Color.white.opacity(0.7) : Color.blue.opacity(0.2))
        .cornerRadius(12)
        .onTapGesture {
            if !appreciation.isRead, let appreciationId = appreciation.id {
                dataController.markAppreciationAsRead(appreciationId)
            }
        }
    }
}

// MARK: - Send Appreciation View (Updated)
struct SendAppreciationView: View {
    let post: WordPost
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var message = ""
    @State private var selectedTemplate: String?
    
    private let templates = [
        "Thank you for sharing this 🙏",
        "Your words touched my heart ❤️",
        "This is exactly what I needed to read today",
        "Beautiful and meaningful words",
        "Thank you for this moment of reflection"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
                
                VStack(spacing: 20) {
                    // Post preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appreciating:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(dataController.userPreferences.selectedBackground.textColor.opacity(0.8))
                        
                        Text(post.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                            .padding(.horizontal)
                        
                        Text(post.content.first ?? "")
                            .font(.system(size: 14))
                            .lineLimit(3)
                            .padding()
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Templates
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Messages:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                        
                        ForEach(templates, id: \.self) { template in
                            Button(action: {
                                message = template
                                selectedTemplate = template
                            }) {
                                Text(template)
                                    .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(selectedTemplate == template ? Color.blue.opacity(0.3) : Color.white.opacity(0.8))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Custom message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or write your own:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(dataController.userPreferences.selectedBackground.textColor)
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Send button
                    Button(action: sendAppreciation) {
                        Text("Send Appreciation")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Send Appreciation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendAppreciation() {
        dataController.sendAppreciation(to: post, message: message)
        dismiss()
    }
}

// MARK: - Settings View (Updated)
struct SettingsView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        ZStack {
            PersistentVideoBackgroundView(backgroundType: dataController.userPreferences.selectedBackground)
            
            List {
                Section("Display") {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.green)
                            .frame(width: 30)
                        Text("Background Music")
                        Spacer()
                        Text("Coming Soon")
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.white.opacity(0.8))
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Words v1.0")
                                .font(.system(size: 16, weight: .medium))
                            Text("A mindful space for sharing thoughts")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.8))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}
