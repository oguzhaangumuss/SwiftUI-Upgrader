import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Kahvaltı"
    case lunch = "Öğle Yemeği"
    case dinner = "Akşam Yemeği"
    case snack = "Ara Öğün"
} 