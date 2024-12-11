import SwiftUI
import FirebaseFirestore

class StatsViewModel: ObservableObject {
    @Published var activityData: [ActivityData] = []
    @Published var calorieData: [CalorieData] = []
    @Published var weightData: [WeightData] = []
    @Published var customRangeData: [CustomRangeData] = []
    @Published var isLoading = false
    
    // Veri modelleri
    struct ActivityData: Identifiable {
        let id = UUID()
        let name: String
        let duration: TimeInterval
        let calories: Double
    }
    
    struct CalorieData: Identifiable {
        let id = UUID()
        let date: Date
        let consumed: Double
        let burned: Double
    }
    
    struct WeightData: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }
    
    struct CustomRangeData: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let type: String
    }
    
    struct WorkoutCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    func fetchStats(for period: StatsPeriod) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        await MainActor.run { isLoading = true }
        
        let (startDate, endDate) = calculateDateRange(for: period)
        
        do {
            // Aktivite dağılımı
            let activities = try await fetchActivityData(userId: userId, start: startDate, end: endDate)
            
            // Kalori verileri
            let calories = try await fetchCalorieData(userId: userId, start: startDate, end: endDate)
            
            // Kilo takibi
            let weights = try await fetchWeightData(userId: userId, start: startDate, end: endDate)
            
            await MainActor.run {
                self.activityData = activities
                self.calorieData = calories
                self.weightData = weights
                self.isLoading = false
            }
        } catch {
            print("❌ İstatistik verileri alınamadı: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    private func calculateDateRange(for period: StatsPeriod) -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let endDate = calendar.startOfDay(for: now)
        
        let startDate: Date
        switch period {
        case .daily:
            startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!
        case .weekly:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        }
        
        return (startDate, endDate)
    }
    
    // Firebase sorguları...
    private func fetchActivityData(userId: String, start: Date, end: Date) async throws -> [ActivityData] {
        let snapshot = try await FirebaseManager.shared.firestore
            .collection("userExercises")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
        
        var activityStats: [String: (duration: TimeInterval, calories: Double)] = [:]
        
        for document in snapshot.documents {
            if let exercise = try? document.data(as: UserExercise.self) {
                let name = exercise.exerciseName ?? "Diğer"
                let duration = exercise.duration
                let calories = exercise.caloriesBurned ?? 0
                
                let current = activityStats[name] ?? (0, 0)
                activityStats[name] = (
                    duration: current.duration + duration,
                    calories: current.calories + calories
                )
            }
        }
        
        return activityStats.map { name, stats in
            ActivityData(
                name: name,
                duration: stats.duration,
                calories: stats.calories
            )
        }.sorted { $0.calories > $1.calories }
    }
    
    private func fetchCalorieData(userId: String, start: Date, end: Date) async throws -> [CalorieData] {
        var dailyData: [Date: (consumed: Double, burned: Double)] = [:]
        let calendar = Calendar.current
        
        // Yakılan kaloriler
        let workouts = try await FirebaseManager.shared.firestore
            .collection("userExercises")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
        
        for document in workouts.documents {
            if let exercise = try? document.data(as: UserExercise.self) {
                let date = calendar.startOfDay(for: exercise.date.dateValue())
                let current = dailyData[date] ?? (0, 0)
                dailyData[date] = (
                    consumed: current.consumed,
                    burned: current.burned + (exercise.caloriesBurned ?? 0)
                )
            }
        }
        
        // Alınan kaloriler
        let meals = try await FirebaseManager.shared.firestore
            .collection("meals")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
        
        for document in meals.documents {
            if let meal = try? document.data(as: Meal.self) {
                let date = calendar.startOfDay(for: meal.date.dateValue())
                let current = dailyData[date] ?? (0, 0)
                dailyData[date] = (
                    consumed: current.consumed + meal.totalCalories,
                    burned: current.burned
                )
            }
        }
        
        return dailyData.map { date, stats in
            CalorieData(
                date: date,
                consumed: stats.consumed,
                burned: stats.burned
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func fetchWeightData(userId: String, start: Date, end: Date) async throws -> [WeightData] {
        let snapshot = try await FirebaseManager.shared.firestore
            .collection("users")
            .document(userId)
            .getDocument()
        
        guard let user = try? snapshot.data(as: User.self),
              let notes = user.progressNotes else {
            return []
        }
        
        return notes
            .filter { note in
                let date = note.date.dateValue()
                return date >= start && date <= end
            }
            .map { note in
                WeightData(
                    date: note.date.dateValue(),
                    weight: note.weight
                )
            }
            .sorted { $0.date < $1.date }
    }
    
    private func fetchWorkoutCount(userId: String, start: Date, end: Date) async throws -> [WorkoutCount] {
        let snapshot = try await FirebaseManager.shared.firestore
            .collection("userExercises")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments()
        
        var dailyCount: [Date: Int] = [:]
        let calendar = Calendar.current
        
        // Her gün için antrenman sayısını hesapla
        for document in snapshot.documents {
            if let exercise = try? document.data(as: UserExercise.self) {
                let date = calendar.startOfDay(for: exercise.date.dateValue())
                dailyCount[date, default: 0] += 1
            }
        }
        
        // Tarihe göre sıralı dizi oluştur
        return dailyCount.map { date, count in
            WorkoutCount(date: date, count: count)
        }.sorted { $0.date < $1.date }
    }
    
    func fetchCustomRangeData(start: Date, end: Date, metrics: Set<CustomDateRangeChart.CustomMetric>) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            var rangeData: [CustomRangeData] = []
            
            // Kalori verilerini getir
            if metrics.contains(.calories) {
                let calorieStats = try await fetchCalorieData(userId: userId, start: start, end: end)
                rangeData += calorieStats.flatMap { stat in [
                    CustomRangeData(date: stat.date, value: stat.consumed, type: "Alınan Kalori"),
                    CustomRangeData(date: stat.date, value: stat.burned, type: "Yakılan Kalori")
                ]}
            }
            
            // Antrenman verilerini getir
            if metrics.contains(.workouts) {
                let workoutStats = try await fetchWorkoutCount(userId: userId, start: start, end: end)
                rangeData += workoutStats.map { stat in
                    CustomRangeData(date: stat.date, value: Double(stat.count), type: "Antrenman")
                }
            }
            
            // Kilo verilerini getir
            if metrics.contains(.weight) {
                let weightStats = try await fetchWeightData(userId: userId, start: start, end: end)
                rangeData += weightStats.map { stat in
                    CustomRangeData(date: stat.date, value: stat.weight, type: "Kilo")
                }
            }
            
            await MainActor.run {
                self.customRangeData = rangeData
                self.isLoading = false
            }
        } catch {
            print("❌ Özel aralık verileri alınamadı: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

enum StatsPeriod {
    case daily, weekly, monthly
} 