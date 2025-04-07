import FirebaseFirestore

struct FoodData: Codable {
    let foods: [FoodItem]
}

struct FoodItem: Codable {
    let name: String
    let brand: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    func toFood(createdBy: String) -> [String: Any] {
        return [
            "name": name,
            "brand": brand,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "imageUrl": nil as Any?,
            "createdBy": createdBy,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
    }
} 