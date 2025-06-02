import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth = Auth.auth()
    let firestore = Firestore.firestore()
    let storage = Storage.storage()
    
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            print("🔄 Auth state değişti: \(user?.uid ?? "nil")")
            if let user = user {
                print("✅ Kullanıcı oturum açtı: \(user.email ?? "email yok") - \(user.uid)")
                Task {
                    await self?.fetchUserData(uid: user.uid)
                    
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
    
    func fetchUserData(uid: String) async {
        print("🔄 FirebaseManager: Kullanıcı verisi getiriliyor... ID: \(uid)")
        isLoading = true
        
        do {
            let document = try await firestore.collection("users").document(uid).getDocument()
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
                await MainActor.run {
                    currentUser = User(
                        id: uid,
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
                    
                    self.isLoading = false
                }
                
                print("✅ FirebaseManager: Kullanıcı verisi dönüştürüldü: \(currentUser?.fullName ?? "nil"), isAdmin: \(isAdmin)")
                print("✅ FirebaseManager: Admin durumu: \(isAdmin)")
                print("👤 Oluşturulan User nesnesi: \(currentUser?.id ?? "id yok"), \(currentUser?.email ?? "email yok"), admin: \(currentUser?.isAdmin)")
            } else {
                print("❌ FirebaseManager: Firestore verisi boş")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ FirebaseManager: Kullanıcı verisi alınamadı: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    func signUp(userData: [String: Any], userId: String) async throws {
        try await firestore.collection("users").document(userId).setData(userData)
        await fetchUserData(uid: userId)
    }
    
    func updateUser(userId: String, data: [String: Any]) async throws {
        try await firestore.collection("users").document(userId).updateData(data)
        await fetchUserData(uid: userId)
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
    }
    
    // MARK: - Storage Functions
    
    // Görsel yükleme metodu
    func storageUploadImage(imageData: Data, path: String) -> String? {
        let storageRef = storage.reference().child(path)
        
        // İmajı yükle ve URL'i al
        var imageUrl: String?
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                print("❌ Görsel yükleme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                return
            }
            
            // Yükleme başarılı olduğunda URL'i al
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("❌ URL alma hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    return
                }
                
                // URL'i döndür
                imageUrl = downloadURL.absoluteString
            }
        }
        
        // Yükleme tamamlanana kadar bekle
        uploadTask.observe(.success) { _ in
            print("✅ Görsel başarıyla yüklendi")
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("❌ Görsel yükleme hatası: \(error.localizedDescription)")
            }
        }
        
        // Yükleme tamamlanana kadar bekle (senkron işlem - normalde async/await kullanılmalı)
        let semaphore = DispatchSemaphore(value: 0)
        uploadTask.observe(.success) { _ in
            semaphore.signal()
        }
        uploadTask.observe(.failure) { _ in
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 60)
        
        return imageUrl
    }
    
    // Async görsel yükleme metodu (daha modern yaklaşım)
    func uploadImageAsync(imageData: Data, path: String) async throws -> String {
        do {
            // Supabase Storage'a yükleme yapmayı deneyelim
            // Dosya adını path'den çıkaralım
            let fileName = path.components(separatedBy: "/").last ?? "image_\(UUID().uuidString).jpg"
            // Dosyayı bucket'ın root kısmına yükle (folderPath boş olmalı)
            let folderPath = ""
            
            print("🔄 Supabase yükleme bilgileri - fileName: \(fileName), folderPath: \(folderPath)")
            
            return try await SupabaseService.shared.uploadImage(
                imageData: imageData,
                path: folderPath,
                fileName: fileName
            )
        } catch {
            print("❌ Supabase Storage yükleme hatası: \(error.localizedDescription)")
            
            // Kullanıcı Firebase Storage kullanmadığını belirtti, bu yüzden hatayı yukarı iletiyoruz
            throw NSError(
                domain: "StorageError",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Görsel yüklenemedi: \(error.localizedDescription). Supabase storage policy kontrol edilmeli."
                ]
            )
        }
    }
    
    // ImgBB'ye görsel yükleme metodu
    private func uploadImageToImgBB(imageData: Data) async throws -> String {
        // ImgBB API anahtarı
        let apiKey = APIKeys.imgBBAPIKey
        
        // API anahtarını doğrula
        if apiKey.isEmpty || apiKey == "YOUR_IMGBB_API_KEY" {
            print("❌ ImgBB API anahtarı geçersiz veya boş")
            throw NSError(domain: "ImgBBError", code: 1000, 
                          userInfo: [NSLocalizedDescriptionKey: "ImgBB API anahtarı geçersiz veya boş"])
        }
        
        // API URL'si
        let url = URL(string: "https://api.imgbb.com/1/upload")!
        
        // URL bileşenleri oluşturalım
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        // URLRequest oluşturalım
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        // Multipart form verisi oluşturalım
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Benzersiz bir dosya adı oluştur
        let filename = "image_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // HTTP body'yi oluşturalım
        var body = Data()
        
        // Resim verisini ekleyelim
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Form verisi sonu
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Request body'ye ekleyelim
        request.httpBody = body
        
        print("🖼️ ImgBB'ye görsel yükleniyor... Dosya adı: \(filename)")
        
        // API çağrısını yapalım
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug için yanıtı yazdır
        if let responseString = String(data: data, encoding: .utf8) {
            print("📊 ImgBB API yanıtı: \(responseString)")
        }
        
        // HTTP yanıtını kontrol edelim
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ImgBBError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz HTTP yanıtı"])
        }
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "Yanıt verisi okunamadı"
            print("❌ ImgBB API Hatası (HTTP \(httpResponse.statusCode)): \(responseString)")
            throw NSError(domain: "ImgBBError", code: httpResponse.statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: "HTTP Hata Kodu: \(httpResponse.statusCode), Yanıt: \(responseString)"])
        }
        
        // JSON yanıtını işleyelim
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool else {
            
            let responseString = String(data: data, encoding: .utf8) ?? "Yanıt verisi okunamadı"
            print("❌ ImgBB Yanıt İşleme Hatası: \(responseString)")
            throw NSError(domain: "ImgBBError", code: 2, 
                         userInfo: [NSLocalizedDescriptionKey: "Geçersiz yanıt formatı: \(responseString)"])
        }
        
        // Success kontrolü
        if !success {
            let statusCode = json["status"] as? Int ?? 0
            let responseString = String(data: data, encoding: .utf8) ?? "Yanıt verisi okunamadı"
            print("❌ ImgBB API Başarısız: \(responseString)")
            throw NSError(domain: "ImgBBError", code: statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: "ImgBB API başarısız: \(responseString)"])
        }
        
        // Data kısmını çıkar
        guard let jsonData = json["data"] as? [String: Any] else {
            let responseString = String(data: data, encoding: .utf8) ?? "Yanıt verisi okunamadı"
            print("❌ ImgBB Yanıt Data Alanı Eksik: \(responseString)")
            throw NSError(domain: "ImgBBError", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Yanıtta data alanı bulunamadı: \(responseString)"])
        }
        
        // Önce display_url (tam görsel URL'si) varsa onu kullan, yoksa url'i dene
        if let displayUrl = jsonData["display_url"] as? String {
            print("✅ ImgBB görsel yükleme başarılı: \(displayUrl)")
            return displayUrl
        } else if let url = jsonData["url"] as? String {
            print("✅ ImgBB görsel yükleme başarılı: \(url)")
            return url
        } else {
            let responseString = String(data: data, encoding: .utf8) ?? "Yanıt verisi okunamadı"
            print("❌ ImgBB URL Bulunamadı: \(responseString)")
            throw NSError(domain: "ImgBBError", code: 4, 
                         userInfo: [NSLocalizedDescriptionKey: "Görsel URL'si bulunamadı: \(responseString)"])
        }
    }
} 