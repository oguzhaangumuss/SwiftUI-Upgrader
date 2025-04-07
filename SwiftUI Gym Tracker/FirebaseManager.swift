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
            print("🔄 Auth state değişti: \(user?.uid ?? "nil")")
            if let user = user {
                print("✅ Kullanıcı oturum açtı: \(user.email ?? "email yok") - \(user.uid)")
                Task {
                    await self?.fetchUserData(userId: user.uid)
                    
                    // Special case for ogz@gmail.com - ensure admin rights in Firestore
                    if user.email?.lowercased() == "ogz@gmail.com" {
                        await self?.ensureAdminRights(userId: user.uid)
                    }
                }
            } else {
                print("❌ Kullanıcı oturumu kapandı")
                self?.currentUser = nil
            }
        }
    }
    
    // Ensure the user has admin rights in Firestore
    @MainActor
    func ensureAdminRights(userId: String) async {
        print("👑 Checking admin rights for user: \(userId)")
        
        do {
            // Update isAdmin to a proper Boolean true in Firestore
            try await firestore.collection("users").document(userId).updateData([
                "isAdmin": true
            ])
            print("👑 Successfully updated isAdmin=true in Firestore")
            
            // Also update the local user object
            if currentUser != nil {
                currentUser?.isAdmin = true
            }
        } catch {
            print("❌ Failed to update admin rights: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func fetchUserData(userId: String) async {
        print("🔄 FirebaseManager: Kullanıcı verisi getiriliyor... ID: \(userId)")
        isLoading = true
        do {
            let document = try await firestore.collection("users").document(userId).getDocument()
            print("📄 Firestore döküman ID: \(document.documentID), var mı?: \(document.exists)")
            
            if let data = document.data() {
                print("✅ FirebaseManager: Firestore verisi: \(data)")
                print("🔍 Veri anahtarları: \(data.keys.joined(separator: ", "))")
                
                // Improve isAdmin handling to support different data types
                var isAdmin = false
                if let adminBool = data["isAdmin"] as? Bool {
                    // Handle direct Boolean value
                    isAdmin = adminBool
                    print("👑 isAdmin değeri (bool): \(adminBool)")
                } else if let adminNumber = data["isAdmin"] as? NSNumber {
                    // Handle numeric value (0 = false, 1 or any other number = true)
                    isAdmin = adminNumber.boolValue
                    print("👑 isAdmin değeri (number): \(adminNumber), dönüştürülen değer: \(isAdmin)")
                } else if let adminInt = data["isAdmin"] as? Int {
                    // Handle integer value
                    isAdmin = adminInt != 0
                    print("👑 isAdmin değeri (int): \(adminInt), dönüştürülen değer: \(isAdmin)")
                } else {
                    print("👑 isAdmin değeri (raw): \(data["isAdmin"] ?? "nil"), tipi: \(type(of: data["isAdmin"]))")
                }
                
                // Support both naming conventions (firstName/lastName vs. userName/userLastName)
                var firstName = data["firstName"] as? String 
                if firstName == nil {
                    firstName = data["userName"] as? String ?? ""
                }
                
                var lastName = data["lastName"] as? String
                if lastName == nil {
                    lastName = data["userLastName"] as? String ?? ""
                }
                
                let email = data["email"] as? String ?? ""
                
                print("📋 Alınan alanlar: firstName=\(firstName ?? ""), lastName=\(lastName ?? ""), email=\(email)")
                
                // Check if this is the admin account by email
                if email.lowercased() == "ogz@gmail.com" {
                    isAdmin = true
                    print("👑 Admin e-posta tespit edildi, isAdmin = true olarak ayarlandı")
                }
                
                // Kullanıcı nesnesini oluştur
                currentUser = User(
                    id: userId,
                    email: email,
                    firstName: firstName ?? "",
                    lastName: lastName ?? "",
                    age: data["age"] as? Int,
                    height: data["height"] as? Double,
                    weight: data["weight"] as? Double,
                    isAdmin: isAdmin, // Güncel admin durumu
                    createdAt: data["createdAt"] as? Timestamp ?? data["date"] as? Timestamp,
                    updatedAt: data["updatedAt"] as? Timestamp,
                    calorieGoal: data["calorieGoal"] as? Int,
                    workoutGoal: data["workoutGoal"] as? Int,
                    weightGoal: data["weightGoal"] as? Double,
                    initialWeight: data["initialWeight"] as? Double,
                    joinDate: data["joinDate"] as? Timestamp ?? data["date"] as? Timestamp ?? Timestamp()
                )
                
                print("✅ FirebaseManager: Kullanıcı verisi dönüştürüldü: \(currentUser?.fullName ?? "nil"), isAdmin: \(isAdmin)")
                print("✅ FirebaseManager: Admin durumu: \(isAdmin)")
                print("👤 Oluşturulan User nesnesi: \(currentUser?.id ?? "id yok"), \(currentUser?.email ?? "email yok"), admin: \(currentUser?.isAdmin)")
            } else {
                print("❌ FirebaseManager: Firestore verisi boş")
            }
        } catch {
            print("❌ FirebaseManager: Kullanıcı verisi alınamadı: \(error)")
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
