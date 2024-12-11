import FirebaseFirestore

struct Food: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let brand: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let imageUrl: String?
    let createdBy: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
} 
