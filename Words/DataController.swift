import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class DataController: ObservableObject {
    @Published var currentUserId: String?
    @Published var posts: [WordPost] = []
    @Published var myAppreciations: [AppreciationMessage] = []
    @Published var sentAppreciations: [AppreciationMessage] = []
    @Published var unreadAppreciationCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userPreferences = UserPreferences()
    
    private let db = Firestore.firestore()
    private var postsListener: ListenerRegistration?
    private var appreciationsListener: ListenerRegistration?
    private var sentAppreciationsListener: ListenerRegistration?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthListener()
        loadUserPreferences()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Cleanup
    private func removeAllListeners() {
        postsListener?.remove()
        appreciationsListener?.remove()
        sentAppreciationsListener?.remove()
        if let authListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }
    
    // MARK: - User Preferences
    func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = preferences
        }
    }
    
    func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }
    
    func updateBackground(_ background: BackgroundType) {
        userPreferences.selectedBackground = background
        saveUserPreferences()
    }
    
    // MARK: - Authentication
    func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUserId = user.uid
                    self?.setupDataListeners()
                } else {
                    self?.signInAnonymously()
                }
            }
        }
    }
    
    func signInAnonymously() {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signInAnonymously { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Authentication failed: \(error.localizedDescription)"
                    print("Auth error: \(error.localizedDescription)")
                    return
                }
                
                if let user = result?.user {
                    self?.currentUserId = user.uid
                    self?.setupDataListeners()
                }
            }
        }
    }
    
    // MARK: - Data Listeners
    private func setupDataListeners() {
        setupPostsListener()
        setupAppreciationsListener()
        setupSentAppreciationsListener()
    }
    
    private func setupPostsListener() {
        postsListener?.remove()
        
        postsListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50) // Limit for performance
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Error fetching posts: \(error.localizedDescription)"
                        print("Error fetching posts: \(error)")
                        return
                    }
                    
                    self?.posts = snapshot?.documents.compactMap { document in
                        do {
                            var post = try document.data(as: WordPost.self)
                            post.id = document.documentID
                            return post
                        } catch {
                            print("Error decoding post \(document.documentID): \(error)")
                            return nil
                        }
                    } ?? []
                }
            }
    }
    
    private func setupAppreciationsListener() {
        guard let userId = currentUserId else { return }
        
        appreciationsListener?.remove()
        
        appreciationsListener = db.collection("appreciations")
            .whereField("receiverId", isEqualTo: userId)
            .order(by: "sentAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Error fetching appreciations: \(error.localizedDescription)"
                        print("Error fetching appreciations: \(error)")
                        return
                    }
                    
                    self?.myAppreciations = snapshot?.documents.compactMap { document in
                        do {
                            var appreciation = try document.data(as: AppreciationMessage.self)
                            appreciation.id = document.documentID
                            return appreciation
                        } catch {
                            print("Error decoding appreciation: \(error)")
                            return nil
                        }
                    } ?? []
                    
                    // Update unread count
                    self?.unreadAppreciationCount = self?.myAppreciations.filter { !$0.isRead }.count ?? 0
                }
            }
    }
    
    private func setupSentAppreciationsListener() {
        guard let userId = currentUserId else { return }
        
        sentAppreciationsListener?.remove()
        
        sentAppreciationsListener = db.collection("appreciations")
            .whereField("senderId", isEqualTo: userId)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching sent appreciations: \(error)")
                        return
                    }
                    
                    self?.sentAppreciations = snapshot?.documents.compactMap { document in
                        do {
                            var appreciation = try document.data(as: AppreciationMessage.self)
                            appreciation.id = document.documentID
                            return appreciation
                        } catch {
                            print("Error decoding sent appreciation: \(error)")
                            return nil
                        }
                    } ?? []
                }
            }
    }
    
    // MARK: - Post Operations
    func createPost(title: String, content: [String], moods: [Mood], fontSize: CGFloat, textAlignment: TextAlignment) {
        guard let userId = currentUserId else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !content.isEmpty,
              !moods.isEmpty else {
            errorMessage = "Please fill all required fields"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let postData: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            "moods": moods.map { $0.rawValue },
            "fontSize": fontSize,
            "textAlignment": textAlignment.rawValue, // Add this
            "createdAt": Timestamp(date: Date()),
            "authorId": userId,
            "appreciationCount": 0
        ]
        
        db.collection("posts").addDocument(data: postData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error creating post: \(error.localizedDescription)"
                    print("Error creating post: \(error)")
                } else {
                    // Post created successfully
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Appreciation Operations
    func sendAppreciation(to post: WordPost, message: String) {
        guard let senderId = currentUserId,
              let postId = post.id else {
            errorMessage = "Unable to send appreciation"
            return
        }
        
        // Check if already appreciated
        if hasUserAppreciatedPost(postId: postId) {
            errorMessage = "You have already appreciated this post"
            return
        }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            errorMessage = "Please write a message"
            return
        }
        
        // Get first 50 characters of first page for display
        let postSnippet = String(post.content.first?.prefix(50) ?? "")
        
        let appreciationData: [String: Any] = [
            "postId": postId,
            "postContent": postSnippet,
            "message": trimmedMessage,
            "sentAt": Timestamp(date: Date()),
            "senderId": senderId,
            "receiverId": post.authorId,
            "isRead": false
        ]
        
        isLoading = true
        
        // Add appreciation
        db.collection("appreciations").addDocument(data: appreciationData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error sending appreciation: \(error.localizedDescription)"
                    print("Error sending appreciation: \(error)")
                    return
                }
                
                // Increment appreciation count on post
                self?.db.collection("posts").document(postId).updateData([
                    "appreciationCount": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("Error updating appreciation count: \(error)")
                    }
                }
            }
        }
    }
    
    func markAppreciationAsRead(_ appreciationId: String) {
        db.collection("appreciations").document(appreciationId).updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print("Error marking appreciation as read: \(error)")
            }
        }
    }
    
    func markAllAppreciationsAsRead() {
        let batch = db.batch()
        
        for appreciation in myAppreciations.filter({ !$0.isRead }) {
            guard let appreciationId = appreciation.id else { continue }
            let docRef = db.collection("appreciations").document(appreciationId)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error marking all appreciations as read: \(error)")
            }
        }
    }
    
    // MARK: - Query Methods
    func getPostsByMoods(_ moods: Set<Mood>) -> [WordPost] {
        if moods.isEmpty {
            return posts
        }
        
        return posts.filter { post in
            !Set(post.moods).isDisjoint(with: moods)
        }
    }
    
    func getMyPosts() -> [WordPost] {
        guard let userId = currentUserId else { return [] }
        return posts.filter { $0.authorId == userId }
    }
    
    func hasUserAppreciatedPost(postId: String) -> Bool {
        guard let userId = currentUserId else { return false }
        
        return sentAppreciations.contains { appreciation in
            appreciation.postId == postId && appreciation.senderId == userId
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}
