import FirebaseFirestore

struct Meal: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let date: Timestamp
    let mealType: MealType
    let foods: [FoodPortion]
    
    var totalCalories: Double {
        foods.reduce(0) { sum, portion in
            sum + ((portion.food.calories * portion.amount) / 100)
        }
    }
}

struct FoodPortion: Codable {
    let food: Food
    let amount: Double // gram cinsinden miktar
} 