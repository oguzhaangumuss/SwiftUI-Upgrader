import FirebaseFirestore

struct UserMeal: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let mealType: MealType
    var foods: [MealFood]
    let date: Timestamp
    let createdAt: Timestamp
    
    var totalCalories: Double {
        foods.reduce(0) { sum, mealFood in
            // Food verilerini getir ve kalori hesapla
            sum + (mealFood.portion * (mealFood.food?.calories ?? 0) / 100)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case mealType
        case foods
        case date
        case createdAt
    }
}

struct MealFood: Codable {
    let foodId: String
    let food: Food?
    let portion: Double // gram cinsinden
}


