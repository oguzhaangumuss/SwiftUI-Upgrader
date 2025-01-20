import FirebaseFirestore

struct WorkoutHistory: Identifiable, Codable {
    let id: String
    let userId: String
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
extension WorkoutHistory {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "templateId": templateId as Any,
            "templateName": templateName,
            "date": date,
            "duration": duration,
            "totalWeight": totalWeight,
            "caloriesBurned": caloriesBurned,
            "exercises": exercises.map { exercise in
                [
                    "id": exercise.id,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.exerciseName,
                    "sets": exercise.sets,
                    "weight": exercise.weight
                ]
            }
        ]
    }
}
