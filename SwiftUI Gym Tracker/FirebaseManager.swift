import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let firestore: Firestore
    
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private init() {
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        // Auth state listener
        auth.addStateDidChangeListener { [weak self] _, user in
            print(" Auth state değişti: \(user?.uid ?? "nil")")
            if let user = user {
                Task {
                    await self?.fetchUserData(userId: user.uid)
                }
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    @MainActor
    func fetchUserData(userId: String) async {
        print("🔄 FirebaseManager: Kullanıcı verisi getiriliyor...")
        isLoading = true
        do {
            let document = try await firestore.collection("users").document(userId).getDocument()
            if let data = document.data() {
                print("✅ FirebaseManager: Firestore verisi: \(data)")
                currentUser = User(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    age: data["age"] as? Int ?? 0,
                    height: data["height"] as? Double ?? 0.0,
                    weight: data["weight"] as? Double ?? 0.0,
                    isAdmin: data["isAdmin"] as? Bool ?? false,
                    createdAt: data["createdAt"] as? Timestamp,
                    updatedAt: data["updatedAt"] as? Timestamp,
                    calorieGoal: data["calorieGoal"] as? Int,
                    workoutGoal: data["workoutGoal"] as? Int,
                    weightGoal: data["weightGoal"] as? Double,
                    initialWeight: data["initialWeight"] as? Double,
                    joinDate: data["joinDate"] as? Timestamp ?? Timestamp(),
                    personalBests: data["personalBests"] as? [String: Double] ?? [:],
                    progressNotes: (data["progressNotes"] as? [[String: Any]])?.compactMap { noteData in
                        guard let id = noteData["id"] as? String,
                              let date = noteData["date"] as? Timestamp,
                              let weight = noteData["weight"] as? Double else {
                            return nil
                        }
                        return User.ProgressNote(
                            id: id,
                            date: date,
                            weight: weight,
                            note: noteData["note"] as? String
                        )
                    } ?? []
                )
                print("✅ FirebaseManager: Kullanıcı verisi dönüştürüldü: \(currentUser?.fullName ?? "nil")")
            } else {
                print("❌ FirebaseManager: Firestore verisi boş")
            }
        } catch {
            print("❌ FirebaseManager: Kullanıcı verisi getirilemedi: \(error)")
        }
        isLoading = false
    }
    
    func signUp(userData: [String: Any], userId: String) async throws {
        try await firestore.collection("users").document(userId).setData(userData)
        await fetchUserData(userId: userId)
    }
    
    func updateUser(userId: String, data: [String: Any]) async throws {
        try await firestore.collection("users").document(userId).updateData(data)
        await fetchUserData(userId: userId)
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
    }
} 
