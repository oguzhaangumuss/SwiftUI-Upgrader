import SwiftUI
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var dailyStats = DailyStats()
    @Published var weeklyStats = DailyStats()
    @Published var monthlyStats = DailyStats()
    
    struct DailyStats {
        var consumedCalories: Double = 0  // Alınan kalori
        var burnedCalories: Double = 0    // Yakılan kalori
        var workoutCount: Int = 0         // Antrenman sayısı
        var weightChange: Double? = nil   // Kilo değişimi
    }
    
    init() {
        Task {
            await fetchUserData()
            await fetchStatsForTimeInterval(.daily)
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
    
    // Seçilen zaman aralığına göre istatistik getirecek fonksiyon
    @MainActor
    func fetchStatsForTimeInterval(_ interval: TimeInterval) async {
        switch interval {
        case .daily:
            await fetchDailyStats()
        case .weekly:
            await fetchWeeklyStats()
        case .monthly:
            await fetchMonthlyStats()
        }
    }
    
    // Günlük istatistikler
    @MainActor
    private func fetchDailyStats() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("❌ Kullanıcı ID'si bulunamadı")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        print("🔍 Günlük istatistikler tarih aralığı: \(today) - \(tomorrow)")
        
        do {
            // Egzersiz verileri ve yakılan kaloriler
            let workouts = try await FirebaseManager.shared.firestore
                .collection("workoutHistory")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("date", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            print("📊 Bulunan günlük egzersiz sayısı: \(workouts.documents.count)")
            
            var stats = DailyStats()
            stats.workoutCount = workouts.documents.count
            
            let workoutDocs = workouts.documents.compactMap { try? $0.data(as: WorkoutHistory.self) }
            print("🏋️ Dönüştürülen günlük egzersiz sayısı: \(workoutDocs.count)")
            
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
            
            print("🍽 Bulunan günlük öğün sayısı: \(userMeals.documents.count)")
            
            let mealDocs = userMeals.documents.compactMap { try? $0.data(as: UserMeal.self) }
            print("�� Dönüştürülen günlük öğün sayısı: \(mealDocs.count)")
            
            // Her öğün için yiyecekleri getir ve kalorileri hesapla
            var totalCalories: Double = 0
            for meal in mealDocs {
                for mealFood in meal.foods {
                    if let food = await fetchFood(id: mealFood.foodId) {
                        let portionCalories = (food.calories * mealFood.portion) / 100
                        totalCalories += portionCalories
                    }
                }
            }
            
            stats.consumedCalories = totalCalories
            
            print("📊 Günlük Özet:")
            print("   Yakılan: \(stats.burnedCalories) kcal")
            print("   Alınan: \(stats.consumedCalories) kcal")
            print("   Antrenman: \(stats.workoutCount)")
            
            self.dailyStats = stats
            
        } catch {
            print("❌ Günlük istatistikler alınamadı: \(error)")
        }
    }
    
    // Haftalık istatistikler
    @MainActor
    private func fetchWeeklyStats() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("❌ Kullanıcı ID'si bulunamadı")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        // Haftanın başlangıç tarihini al (Pazartesi)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        // Haftanın bitiş tarihini al (Pazar)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? today
        
        print("🔍 Haftalık istatistikler tarih aralığı: \(weekStart) - \(weekEnd)")
        
        do {
            // Egzersiz verileri ve yakılan kaloriler
            let workouts = try await FirebaseManager.shared.firestore
                .collection("workoutHistory")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: weekStart))
                .whereField("date", isLessThan: Timestamp(date: weekEnd))
                .getDocuments()
            
            print("📊 Bulunan haftalık egzersiz sayısı: \(workouts.documents.count)")
            
            var stats = DailyStats()
            stats.workoutCount = workouts.documents.count
            
            let workoutDocs = workouts.documents.compactMap { try? $0.data(as: WorkoutHistory.self) }
            print("🏋️ Dönüştürülen haftalık egzersiz sayısı: \(workoutDocs.count)")
            
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
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: weekStart))
                .whereField("date", isLessThan: Timestamp(date: weekEnd))
                .getDocuments()
            
            print("🍽 Bulunan haftalık öğün sayısı: \(userMeals.documents.count)")
            
            let mealDocs = userMeals.documents.compactMap { try? $0.data(as: UserMeal.self) }
            print("🍳 Dönüştürülen haftalık öğün sayısı: \(mealDocs.count)")
            
            // Her öğün için yiyecekleri getir ve kalorileri hesapla
            var totalCalories: Double = 0
            for meal in mealDocs {
                for mealFood in meal.foods {
                    if let food = await fetchFood(id: mealFood.foodId) {
                        let portionCalories = (food.calories * mealFood.portion) / 100
                        totalCalories += portionCalories
                    }
                }
            }
            
            stats.consumedCalories = totalCalories
            
            print("📊 Haftalık Özet:")
            print("   Yakılan: \(stats.burnedCalories) kcal")
            print("   Alınan: \(stats.consumedCalories) kcal")
            print("   Antrenman: \(stats.workoutCount)")
            
            self.weeklyStats = stats
            
        } catch {
            print("❌ Haftalık istatistikler alınamadı: \(error)")
        }
    }
    
    // Aylık istatistikler
    @MainActor
    private func fetchMonthlyStats() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("❌ Kullanıcı ID'si bulunamadı")
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Ay başlangıcını bul
        var components = calendar.dateComponents([.year, .month], from: today)
        components.day = 1
        let monthStart = calendar.date(from: components)!
        
        // Bir sonraki ay
        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        let monthEnd = calendar.date(byAdding: nextMonthComponents, to: monthStart)!
        
        print("🔍 Aylık istatistikler tarih aralığı: \(monthStart) - \(monthEnd)")
        
        do {
            // Egzersiz verileri ve yakılan kaloriler
            let workouts = try await FirebaseManager.shared.firestore
                .collection("workoutHistory")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
                .whereField("date", isLessThan: Timestamp(date: monthEnd))
                .getDocuments()
            
            print("📊 Bulunan aylık egzersiz sayısı: \(workouts.documents.count)")
            
            var stats = DailyStats()
            stats.workoutCount = workouts.documents.count
            
            let workoutDocs = workouts.documents.compactMap { try? $0.data(as: WorkoutHistory.self) }
            print("🏋️ Dönüştürülen aylık egzersiz sayısı: \(workoutDocs.count)")
            
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
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
                .whereField("date", isLessThan: Timestamp(date: monthEnd))
                .getDocuments()
            
            print("🍽 Bulunan aylık öğün sayısı: \(userMeals.documents.count)")
            
            let mealDocs = userMeals.documents.compactMap { try? $0.data(as: UserMeal.self) }
            print("🍳 Dönüştürülen aylık öğün sayısı: \(mealDocs.count)")
            
            // Her öğün için yiyecekleri getir ve kalorileri hesapla
            var totalCalories: Double = 0
            for meal in mealDocs {
                for mealFood in meal.foods {
                    if let food = await fetchFood(id: mealFood.foodId) {
                        let portionCalories = (food.calories * mealFood.portion) / 100
                        totalCalories += portionCalories
                    }
                }
            }
            
            stats.consumedCalories = totalCalories
            
            print("📊 Aylık Özet:")
            print("   Yakılan: \(stats.burnedCalories) kcal")
            print("   Alınan: \(stats.consumedCalories) kcal")
            print("   Antrenman: \(stats.workoutCount)")
            
            self.monthlyStats = stats
            
        } catch {
            print("❌ Aylık istatistikler alınamadı: \(error)")
        }
    }
    
    // Seçilen zaman aralığı için alınan kalorileri döndüren fonksiyon
    func getConsumedCalories(for interval: TimeInterval) -> Double {
        switch interval {
        case .daily:
            return dailyStats.consumedCalories
        case .weekly:
            return weeklyStats.consumedCalories
        case .monthly:
            return monthlyStats.consumedCalories
        }
    }
    
    // Seçilen zaman aralığı için yakılan kalorileri döndüren fonksiyon
    func getBurnedCalories(for interval: TimeInterval) -> Double {
        switch interval {
        case .daily:
            return dailyStats.burnedCalories
        case .weekly:
            return weeklyStats.burnedCalories
        case .monthly:
            return monthlyStats.burnedCalories
        }
    }
    
    // Seçilen zaman aralığı için tüm istatistikleri döndüren fonksiyon
    func getStats(for interval: TimeInterval) -> DailyStats {
        switch interval {
        case .daily:
            return dailyStats
        case .weekly:
            return weeklyStats
        case .monthly:
            return monthlyStats
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
