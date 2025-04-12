import SwiftUI
import FirebaseFirestore

class MealsViewModel: ObservableObject {
    @Published var meals: [UserMeal] = []
    @Published var isLoading = false
    
    private let db = FirebaseManager.shared.firestore
    private let foodsViewModel = FoodsViewModel.shared
    
    @MainActor
    func fetchMeals(for date: Date) async {
        await MainActor.run {
            isLoading = true
            meals = []
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        await fetchMealsBetween(start: startOfDay, end: endOfDay)
    }
    
    func fetchMealsForWeek(startDate: Date) async {
        await MainActor.run {
            isLoading = true
            meals = []
        }
        
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfDay(for: startDate)
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        await fetchMealsBetween(start: startOfWeek, end: endOfWeek)
    }
    
    func fetchMealsForMonth(startDate: Date) async {
        await MainActor.run {
            isLoading = true
            meals = []
        }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfDay(for: startDate)
        
        var components = DateComponents()
        components.month = 1
        let endOfMonth = calendar.date(byAdding: components, to: startOfMonth)!
        
        await fetchMealsBetween(start: startOfMonth, end: endOfMonth)
    }
    
    private func fetchMealsBetween(start: Date, end: Date) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
                .whereField("date", isLessThan: Timestamp(date: end))
                .getDocuments()
            
            let fetchedMeals = snapshot.documents.compactMap { document -> UserMeal? in
                try? document.data(as: UserMeal.self)
            }
            
            await MainActor.run {
                self.meals = fetchedMeals.sorted(by: { $0.date.dateValue() < $1.date.dateValue() })
                self.isLoading = false
            }
            
        } catch {
            print("Error fetching meals: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func meals(for type: MealType) -> [UserMeal]? {
        let mealsForType = meals.filter { $0.mealType == type }
        return mealsForType.isEmpty ? nil : mealsForType
    }
    
    func calculateDailySummary() -> NutritionSummary {
        var summary = NutritionSummary()
        
        for meal in meals {
            for mealFood in meal.foods {
                if let food = foodsViewModel.getFood(by: mealFood.foodId) {
                    let portionMultiplier = mealFood.portion / 100.0
                    
                    summary.calories += Int(Double(food.calories) * portionMultiplier)
                    summary.protein += food.protein * portionMultiplier
                    summary.carbs += food.carbs * portionMultiplier
                    summary.fat += food.fat * portionMultiplier
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