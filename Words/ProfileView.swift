import SwiftUI

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationView {
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
                
                Section("Settings") {
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            
                            Text("App Settings")
                        }
                    }
                }
                
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
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - My Words View
struct MyWordsView: View {
    @EnvironmentObject var dataController: DataController
    
    var myPosts: [WordPost] {
        dataController.getMyPosts()
    }
    
    var body: some View {
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
        .navigationTitle("My Words")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Empty My Words View
struct EmptyMyWordsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("You haven't shared any words yet")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary)
            
            Text("When you create a post,\nit will appear here")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
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
        // In MyWordCard, replace the content display with:
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(1)
            
            Text(post.content.first ?? "")
                .font(.system(size: 16))
                .lineLimit(3)
                .foregroundColor(.secondary)
        }
            
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
            
            Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(post.backgroundType.gradient.opacity(0.3))
        .cornerRadius(12)
        .onTapGesture {
            showingFullPost = true
        }
        .sheet(isPresented: $showingFullPost) {
            FullPostView(post: post, showAppreciationButton: false)
        }
    }
}

// MARK: - Appreciation Inbox View
struct AppreciationInboxView: View {
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
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
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No appreciations yet")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary)
            
            Text("When someone appreciates your words,\ntheir messages will appear here")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
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
        .background(appreciation.isRead ? Color(UIColor.systemGray6) : Color.blue.opacity(0.1))
        .cornerRadius(12)
        .onTapGesture {
            if !appreciation.isRead, let appreciationId = appreciation.id {
                dataController.markAppreciationAsRead(appreciationId)
            }
        }
    }
}

// MARK: - Send Appreciation View
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
            VStack(spacing: 20) {
                // Post preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appreciating:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(post.content)
                        .font(.system(size: 14))
                        .lineLimit(3)
                        .padding()
                        .background(post.backgroundType.gradient.opacity(0.3))
                        .cornerRadius(8)
                }
                
                // Templates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Messages:")
                        .font(.system(size: 16, weight: .medium))
                    
                    ForEach(templates, id: \.self) { template in
                        Button(template) {
                            message = template
                            selectedTemplate = template
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(selectedTemplate == template ? Color.blue.opacity(0.2) : Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Custom message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or write your own:")
                        .font(.system(size: 16, weight: .medium))
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Send button
                Button("Send Appreciation") {
                    sendAppreciation()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
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

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        List {
            Section("Display") {
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Text("Background Theme")
                    Spacer()
                    Text("Coming Soon")
                        .foregroundColor(.secondary)
                }
                
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
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}//
//  ProfileView.swift
//  Words
//
//  Created by Hiro on 2025/07/24.
//

