import Foundation

struct SimpleMeal: Identifiable {
    let id: String
    let name: String
    let quantity: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let period: String
    let note: String?
    let foodId: String
    let createdAt: Date
    let foods: [SimpleFoodItem]
    
    var totalCalories: Double {
        if foods.isEmpty {
            return calories
        }
        return foods.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        if foods.isEmpty {
            return protein
        }
        return foods.reduce(0) { $0 + ($1.protein ?? 0) }
    }
    
    var totalCarbs: Double {
        if foods.isEmpty {
            return carbs
        }
        return foods.reduce(0) { $0 + ($1.carbs ?? 0) }
    }
    
    var totalFat: Double {
        if foods.isEmpty {
            return fat
        }
        return foods.reduce(0) { $0 + ($1.fat ?? 0) }
    }
    
    var mealType: MealPeriod {
        return MealPeriod(rawValue: period) ?? .breakfast
    }
}

struct SimpleFoodItem: Identifiable {
    let id: String
    let name: String
    let quantity: Double
    let calories: Double
    var protein: Double?
    var carbs: Double?
    var fat: Double?
} 