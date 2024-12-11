import SwiftUI
import FirebaseFirestore

class CalorieBalanceViewModel: ObservableObject {
    @Published var consumedCalories: Double = 0
    @Published var burnedCalories: Double = 0
    @Published var activityDistribution: [ActivityData] = []
    @Published var weeklyData: [DayCalories] = []
    @Published var calorieGoal: Int? = nil
    
    func fetchCalorieData(userId: String) async {
        // Kalori hedefini al
        do {
            let userDoc = try await FirebaseManager.shared.firestore
                .collection("users")
                .document(userId)
                .getDocument()
            
            if let user = try? userDoc.data(as: User.self) {
                await MainActor.run {
                    self.calorieGoal = user.calorieGoal
                }
            }
        } catch {
            print("Kullanıcı bilgileri alınamadı: \(error)")
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Yakılan kalorileri hesapla
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("date", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            var totalBurned: Double = 0
            var activityStats: [String: Double] = [:]
            
            for document in snapshot.documents {
                if let workout = try? document.data(as: UserExercise.self),
                   let calories = workout.caloriesBurned {
                    totalBurned += calories
                    let exerciseName = workout.exerciseName ?? "Diğer"
                    activityStats[exerciseName, default: 0] += calories
                }
            }
            
            await MainActor.run {
                self.burnedCalories = totalBurned
                self.activityDistribution = activityStats.map { name, calories in
                    ActivityData(name: name, calories: calories)
                }.sorted { $0.calories > $1.calories }
            }
        } catch {
            print("Egzersiz verileri alınamadı: \(error)")
        }
        
        // Alınan kalorileri hesapla
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("meals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("date", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            var totalConsumed: Double = 0
            
            for document in snapshot.documents {
                if let meal = try? document.data(as: Meal.self) {
                    for portion in meal.foods {
                        // Her porsiyon için kalori hesabı
                        let portionCalories = (portion.food.calories * portion.amount) / 100
                        totalConsumed += portionCalories
                    }
                }
            }
            
            await MainActor.run {
                self.consumedCalories = totalConsumed
            }
        } catch {
            print("Öğün verileri alınamadı: \(error)")
        }
    }
}

struct DayCalories: Identifiable {
    let id = UUID()
    let date: Date
    let consumed: Double
    let burned: Double
}

struct FoodData: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
}

struct ActivityData: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
} 