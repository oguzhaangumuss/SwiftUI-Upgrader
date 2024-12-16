import FirebaseFirestore

struct ExerciseRating: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let userId: String
    let rating: Int // 1-5 arası
    let createdAt: Timestamp
    let updatedAt: Timestamp
} 