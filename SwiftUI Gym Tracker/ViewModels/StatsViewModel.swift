import SwiftUI
import FirebaseFirestore
import Foundation

class StatsViewModel: ObservableObject {
    // MARK: - Veri Modelleri
    struct CustomRangeData: Identifiable {
        let id = UUID()
        let date: Date
        var calories: Double
        var workouts: Int
        var weight: Double?
    }
    
    struct ActivityData: Identifiable {
        let id = UUID()
        let date: Date
        var workoutCount: Int
        var duration: Double
    }
    
    struct CalorieData: Identifiable {
        let id = UUID()
        let date: Date
        var burned: Double
        var consumed: Double
    }
    
    struct WeightData: Identifiable {
        let id = UUID()
        let date: Date
        var weight: Double
    }
    
    // MARK: - Published Properties
    @Published var activityData: [ActivityData] = []
    @Published var calorieData: [CalorieData] = []
    @Published var weightData: [WeightData] = []
    @Published var customRangeData: [CustomRangeData] = []
    @Published var isLoading = false
    
    // MARK: - Yardımcı Fonksiyonlar
    private func fetchWorkouts(userId: String, start: Date, end: Date) async throws -> [ActivityData] {
        let snapshot = try await FirebaseManager.shared.firestore
            .collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
            
        return snapshot.documents.compactMap { document in
            guard let workout = try? document.data(as: WorkoutHistory.self) else { return nil }
            return ActivityData(
                date: workout.date.dateValue(),
                workoutCount: 1,
                duration: workout.duration ?? 0.0
            )
        }
    }
    
    private func fetchCalories(userId: String, start: Date, end: Date) async throws -> [CalorieData] {
        let workouts = try await FirebaseManager.shared.firestore
            .collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
            
        var caloriesByDate: [Date: CalorieData] = [:]
        
        // Yakılan kalorileri hesapla
        for document in workouts.documents {
            if let workout = try? document.data(as: WorkoutHistory.self) {
                let date = Calendar.current.startOfDay(for: workout.date.dateValue())
                let burned = workout.caloriesBurned ?? 0
                
                if var existing = caloriesByDate[date] {
                    existing.burned += burned
                    caloriesByDate[date] = existing
                } else {
                    caloriesByDate[date] = CalorieData(date: date, burned: burned, consumed: 0)
                }
            }
        }
        
        // Alınan kalorileri hesapla
        let meals = try await FirebaseManager.shared.firestore
            .collection("userMeals")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
            
        for document in meals.documents {
            if let meal = try? document.data(as: UserMeal.self) {
                let date = Calendar.current.startOfDay(for: meal.date.dateValue())
                let consumed = meal.totalCalories ?? 0
                
                if var existing = caloriesByDate[date] {
                    existing.consumed += consumed
                    caloriesByDate[date] = existing
                } else {
                    caloriesByDate[date] = CalorieData(date: date, burned: 0, consumed: consumed)
                }
            }
        }
        
        return Array(caloriesByDate.values)
    }
    
    private func calculateDateRange(for period: StatsPeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .daily:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
            
        case .weekly:
            // Haftanın başlangıcını al (Pazartesi)
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return (weekStart, weekEnd)
            
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return (startOfMonth, nextMonth)
        }
    }
    
    // Özel tarih aralığı için veri çekme fonksiyonu
    private func fetchCustomRangeData(userId: String, start: Date, end: Date) async throws -> [CustomRangeData] {
        // Antrenman verileri
        let workouts = try await fetchWorkouts(userId: userId, start: start, end: end)
        
        // Kalori verileri
        let calories = try await fetchCalories(userId: userId, start: start, end: end)
        
        // Verileri birleştir
        var customData: [Date: CustomRangeData] = [:]
        
        // Antrenman verilerini ekle
        for workout in workouts {
            let date = Calendar.current.startOfDay(for: workout.date)
            if var existing = customData[date] {
                existing.workouts += workout.workoutCount
                customData[date] = existing
            } else {
                customData[date] = CustomRangeData(
                    date: date,
                    calories: 0,
                    workouts: workout.workoutCount,
                    weight: nil
                )
            }
        }
        
        // Kalori verilerini ekle
        for calorie in calories {
            let date = Calendar.current.startOfDay(for: calorie.date)
            if var existing = customData[date] {
                existing.calories = calorie.burned - calorie.consumed
                customData[date] = existing
            } else {
                customData[date] = CustomRangeData(
                    date: date,
                    calories: calorie.burned - calorie.consumed,
                    workouts: 0,
                    weight: nil
                )
            }
        }
        
        return Array(customData.values).sorted(by: { $0.date < $1.date })
    }
    
    // MARK: - Ana Fonksiyon
    @MainActor
    func fetchStats(for period: StatsPeriod) async {
        isLoading = true
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("❌ Kullanıcı ID'si bulunamadı")
            isLoading = false
            return
        }
        
        let (startDate, endDate) = calculateDateRange(for: period)
        print("\n📊 İstatistik Verileri Çekiliyor:")
        print("📅 Periyot: \(period)")
        print("📅 Başlangıç: \(startDate)")
        print("📅 Bitiş: \(endDate)")
        
        do {
            let workouts = try await fetchWorkouts(userId: userId, start: startDate, end: endDate)
            let calories = try await fetchCalories(userId: userId, start: startDate, end: endDate)
            let customRange = try await fetchCustomRangeData(userId: userId, start: startDate, end: endDate)
            
            await MainActor.run {
                self.activityData = workouts
                self.calorieData = calories
                self.customRangeData = customRange
                self.isLoading = false
            }
            
        } catch {
            print("❌ Veri çekme hatası: \(error)")
            isLoading = false
        }
    }
}

enum StatsPeriod {
    case daily, weekly, monthly
} 

