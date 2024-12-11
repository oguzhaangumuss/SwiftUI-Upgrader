import SwiftUI
import FirebaseFirestore

class NutritionStatsViewModel: ObservableObject {
    @Published var currentStats = NutritionStats()
    @Published var chartData: [NutritionDataPoint] = []
    
    @MainActor
    func fetchStats(for period: NutritionStatsView.StatsPeriod) async {
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        
        switch period {
        case .daily:
            startDate = calendar.startOfDay(for: now)
        case .weekly:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        }
        
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                .whereField("date", isLessThan: Timestamp(date: now))
                .getDocuments()
            
            var stats = NutritionStats()
            var dataPoints: [Date: NutritionDataPoint] = [:]
            
            for document in snapshot.documents {
                guard let meal = try? document.data(as: UserMeal.self) else { continue }
                
                for mealFood in meal.foods {
                    guard let food = FoodsViewModel.shared.foods.first(where: { $0.id == mealFood.foodId }) else { continue }
                    
                    let multiplier = mealFood.portion / 100.0
                    let calories = food.calories * multiplier
                    let protein = food.protein * multiplier
                    let carbs = food.carbs * multiplier
                    let fat = food.fat * multiplier
                    
                    stats.totalCalories += calories
                    stats.totalProtein += protein
                    stats.totalCarbs += carbs
                    stats.totalFat += fat
                    
                    let date = meal.date.dateValue()
                    let dayStart = calendar.startOfDay(for: date)
                    
                    var point = dataPoints[dayStart] ?? NutritionDataPoint(date: dayStart)
                    point.calories += calories
                    dataPoints[dayStart] = point
                }
            }
            
            currentStats = stats
            chartData = dataPoints.values.sorted { $0.date < $1.date }
            
        } catch {
            print("İstatistikler getirilemedi: \(error)")
        }
    }
}

struct NutritionStats {
    var totalCalories: Double = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFat: Double = 0
}

struct NutritionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    var calories: Double = 0
} 
