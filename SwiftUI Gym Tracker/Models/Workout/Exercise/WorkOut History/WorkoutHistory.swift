import FirebaseFirestore

struct WorkoutHistory: Identifiable, Codable {
    let id: String
    let templateId: String?
    let templateName: String
    let date: Timestamp
    let duration: TimeInterval
    let totalWeight: Double
    let caloriesBurned: Double
    let exercises: [HistoryExercise]
    
    struct HistoryExercise: Identifiable, Codable {
        let id: String
        let exerciseId: String
        let exerciseName: String
        let sets: Int
        let weight: Double
        
        var formattedSets: String {
            "\(Int(weight)) kg x \(sets)"
        }
    }
} 