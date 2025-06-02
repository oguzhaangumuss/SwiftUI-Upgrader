import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class AdminFoodSeederViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successCount = 0
    
    private let db = FirebaseManager.shared.firestore
    
    // A simpler approach to add foods one by one
    @MainActor
    private func addFoodsOneByOne(foods: [FoodItem], userId: String) async -> Bool {
        print("🔄 AdminFoodSeeder: Besinleri tek tek eklemeye başlıyor...")
        successCount = 0
        
        for (index, food) in foods.enumerated() {
            do {
                let foodData = food.toFood(createdBy: userId)
                let docRef = db.collection("foods").document()
                
                try await docRef.setData(foodData)
                
                successCount += 1
                print("✅ AdminFoodSeeder: \(index+1)/\(foods.count) - \(food.name) eklendi")
                
                // A small delay to avoid overwhelming Firestore
                if index % 5 == 0 && index > 0 {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay every 5 items
                }
            } catch {
                print("❌ AdminFoodSeeder: Besin eklenirken hata: \(error.localizedDescription)")
                errorMessage = "Besin ekleme işlemi \(successCount) besin eklendikten sonra durdu: \(error.localizedDescription)"
                return false
            }
        }
        
        return true
    }
    
    // For direct Firestore REST API calls
    private func addFoodDirectly(foods: [FoodItem], userId: String) async -> Bool {
        // Get the ID token for authentication
        do {
            let token = try await Auth.auth().currentUser?.getIDToken() ?? ""
            print("✅ ID token retrieved: \(token.prefix(15))...")
            
            let projectId = "swiftui-gym-tracker" // Your actual Firebase project ID
            let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents/foods")!
            
            for (index, food) in foods.enumerated() {
                let foodData = food.toFood(createdBy: userId)
                
                // Convert to Firestore REST API format
                var fields: [String: [String: Any]] = [:]
                
                for (key, value) in foodData {
                    if let stringValue = value as? String {
                        fields[key] = ["stringValue": stringValue]
                    } else if let doubleValue = value as? Double {
                        fields[key] = ["doubleValue": doubleValue]
                    } else if let intValue = value as? Int {
                        fields[key] = ["integerValue": intValue]
                    } else if let timestamp = value as? Timestamp {
                        fields[key] = ["timestampValue": ISO8601DateFormatter().string(from: timestamp.dateValue())]
                    } else if value == nil {
                        fields[key] = ["nullValue": NSNull()]
                    }
                }
                
                let body: [String: Any] = ["fields": fields]
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData
                
                print("📤 Directly uploading food \(index+1)/\(foods.count): \(food.name)")
                
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.successCount += 1
                    }
                    print("✅ Successfully uploaded food: \(food.name)")
                } else {
                    print("❌ Failed to upload food: \(food.name), response: \(response)")
                    return false
                }
            }
            
            return true
        } catch {
            print("❌ Error in direct upload: \(error.localizedDescription)")
            return false
        }
    }
    
    @MainActor
    func seedFoods() async {
        print("🔍 AdminFoodSeeder: İşlem başlıyor...")
        
        // Check authentication status
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Oturum açılmamış"
            print("❌ AdminFoodSeeder: Oturum açılmamış")
            return
        }
        
        print("✅ AdminFoodSeeder: Auth durumu: Giriş yapılmış, UID: \(currentUser.uid)")
        print("✅ AdminFoodSeeder: Email: \(currentUser.email ?? "email yok")")
        
        guard let user = FirebaseManager.shared.currentUser else {
            errorMessage = "Kullanıcı verisi yüklenemedi"
            print("❌ AdminFoodSeeder: FirebaseManager.currentUser nil")
            return
        }
        
        print("✅ AdminFoodSeeder: FirebaseManager.currentUser yüklendi: \(user.fullName), Admin: \(user.isAdmin)")
        
        guard user.isAdmin else {
            errorMessage = "Bu işlem için admin yetkisi gerekiyor"
            print("❌ AdminFoodSeeder: Admin yetkisi gerekiyor, mevcut durum: \(user.isAdmin)")
            return
        }
        
        isLoading = true
        errorMessage = ""
        successCount = 0
        
        do {
            print("📦 AdminFoodSeeder: foods.json dosyası yükleniyor...")
            let foodData = try Bundle.main.decode(FoodData.self, from: "foods")
            print("✅ AdminFoodSeeder: \(foodData.foods.count) besin verisi yüklendi")
            
            // Try the one-by-one method first (most likely to work)
            print("📤 AdminFoodSeeder: Tek tek ekleme yöntemi deneniyor...")
            let oneByOneSuccess = await addFoodsOneByOne(foods: foodData.foods, userId: currentUser.uid)
            
            if oneByOneSuccess {
                print("✅ AdminFoodSeeder: Tek tek ekleme yöntemi başarılı!")
                return
            }
            
            // Try the batch method
            print("📤 AdminFoodSeeder: Batch yöntemi deneniyor...")
            do {
                let batch = db.batch()
                
                for food in foodData.foods {
                    let docRef = db.collection("foods").document()
                    batch.setData(food.toFood(createdBy: currentUser.uid), forDocument: docRef)
                }
                
                try await batch.commit()
                print("✅ AdminFoodSeeder: Batch işlemi başarılı, \(foodData.foods.count) besin eklendi")
                successCount = foodData.foods.count
                
            } catch let firestoreError as NSError {
                print("⚠️ AdminFoodSeeder: Batch işlemi başarısız, API yöntemi deneniyor...")
                print("❌ AdminFoodSeeder: Firestore Hata Kodu: \(firestoreError.code)")
                
                if firestoreError.code == 7 { // Permission denied error code
                    print("🔑 AdminFoodSeeder: Yetki hatası algılandı, doğrudan API yöntemi deneniyor...")
                    
                    // Try direct API access as fallback
                    let success = await addFoodDirectly(foods: foodData.foods, userId: currentUser.uid)
                    
                    if !success {
                        errorMessage = "Veri yükleme yöntemlerinin tamamı başarısız oldu. Firestore kurallarınızı kontrol edin."
                    } else {
                        print("✅ AdminFoodSeeder: Doğrudan erişim yöntemi başarılı")
                    }
                } else {
                    errorMessage = "Besinler eklenirken hata oluştu: \(firestoreError.localizedDescription)"
                    successCount = 0
                }
            }
            
        } catch BundleError.fileNotFound {
            print("❌ AdminFoodSeeder: foods.json dosyası bulunamadı")
            errorMessage = "foods.json dosyası bulunamadı"
        } catch {
            print("❌ AdminFoodSeeder: Beklenmeyen hata: \(error.localizedDescription)")
            errorMessage = "Besinler eklenirken hata oluştu: \(error.localizedDescription)"
            successCount = 0
        }
        
        isLoading = false
    }
} 