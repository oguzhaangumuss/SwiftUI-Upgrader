import SwiftUI
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var todaysStats = DailyStats()
    
    struct DailyStats {
        var consumedCalories: Double = 2  // Alınan kalori
        var burnedCalories: Double = 2    // Yakılan kalori
        var workoutCount: Int = 2         // Antrenman sayısı
        var weightChange: Double? = nil    // Kilo değişimi
    }
    
    init() {
        Task {
            await fetchUserData()
            await fetchTodaysStats()
        }
    }
    
    @MainActor
    func fetchUserData() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let doc = try await FirebaseManager.shared.firestore
                .collection("users")
                .document(userId)
                .getDocument()
            
            user = try doc.data(as: User.self)
        } catch {
            print("❌ Kullanıcı bilgileri alınamadı: \(error)")
        }
    }
    
    @MainActor
    func fetchTodaysStats() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("❌ Kullanıcı ID'si bulunamadı")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        print("🔍 Tarih aralığı: \(today) - \(tomorrow)")
        
        do {
            // Egzersiz verileri ve yakılan kaloriler
            let workouts = try await FirebaseManager.shared.firestore
                .collection("workoutHistory")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("date", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            print("📊 Bulunan egzersiz sayısı: \(workouts.documents.count)")
            
            var stats = DailyStats()
            stats.workoutCount = workouts.documents.count
            
            let workoutDocs = workouts.documents.compactMap { try? $0.data(as: WorkoutHistory.self) }
            print("🏋️ Dönüştürülen egzersiz sayısı: \(workoutDocs.count)")
            
            stats.burnedCalories = workoutDocs
                .compactMap { workout in
                    let calories = workout.caloriesBurned
                    return calories
                }
                .reduce(0, +)
            
            // Öğün verileri ve alınan kaloriler
            let userMeals = try await FirebaseManager.shared.firestore
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("date", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            print("🍽 Bulunan öğün sayısı: \(userMeals.documents.count)")
            
            let mealDocs = userMeals.documents.compactMap { try? $0.data(as: UserMeal.self) }
            print("🍳 Dönüştürülen öğün sayısı: \(mealDocs.count)")
            
            // Her öğün için yiyecekleri getir ve kalorileri hesapla
            var totalCalories: Double = 0
            for meal in mealDocs {
                for mealFood in meal.foods {
                    if let food = await fetchFood(id: mealFood.foodId) {
                        let portionCalories = (food.calories * mealFood.portion) / 100
                        totalCalories += portionCalories
                        print("   - \(food.name): \(portionCalories) kcal")
                    }
                }
                print("   - \(meal.mealType.rawValue): \(totalCalories) kcal")
            }
            
            stats.consumedCalories = totalCalories
            
            print("📊 Günlük Özet:")
            print("   Yakılan: \(stats.burnedCalories) kcal")
            print("   Alınan: \(stats.consumedCalories) kcal")
            print("   Antrenman: \(stats.workoutCount)")
            
            todaysStats = stats
            
        } catch {
            print("❌ İstatistikler alınamadı: \(error)")
        }
    }
    
    // Yiyecek verilerini getirmek için yardımcı fonksiyon
    private func fetchFood(id: String) async -> Food? {
        do {
            let doc = try await FirebaseManager.shared.firestore
                .collection("foods")
                .document(id)
                .getDocument()
            return try? doc.data(as: Food.self)
        } catch {
            print("❌ Yiyecek getirilemedi: \(error)")
            return nil
        }
    }
} 
