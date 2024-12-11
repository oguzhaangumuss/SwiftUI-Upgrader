import SwiftUI
import FirebaseFirestore

class MealsViewModel: ObservableObject {
    @Published var meals: [UserMeal] = []
    @Published var isLoading = false
    
    private let db = FirebaseManager.shared.firestore
    private let foodsViewModel = FoodsViewModel.shared
    
    @MainActor
    func fetchMeals(for date: Date) async {
        isLoading = true
        meals = []
        
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            isLoading = false
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let snapshot = try await db.collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .order(by: "date")
                .getDocuments()
            
            meals = snapshot.documents.compactMap { try? $0.data(as: UserMeal.self) }
        } catch {
            print("Öğünler getirilemedi: \(error)")
        }
        
        isLoading = false
    }
    
    func meals(for type: MealType) -> [UserMeal]? {
        let typeMeals = meals.filter { $0.mealType == type }
        return typeMeals.isEmpty ? nil : typeMeals
    }
    
    func calculateDailySummary() -> NutritionSummary {
        var summary = NutritionSummary()
        
        for meal in meals {
            for mealFood in meal.foods {
                if let food = foodsViewModel.getFood(by: mealFood.foodId) {
                    let portion = mealFood.portion / 100.0 // gram to percentage
                    summary.calories += Int(food.calories * portion)
                    summary.protein += food.protein * portion
                    summary.carbs += food.carbs * portion
                    summary.fat += food.fat * portion
                }
            }
        }
        
        return summary
    }
}

struct NutritionSummary {
    var calories: Int = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
} 