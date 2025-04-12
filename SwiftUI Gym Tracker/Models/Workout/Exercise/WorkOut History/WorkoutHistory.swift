import FirebaseFirestore
import Foundation

struct WorkoutHistory: Identifiable, Codable {
    let id: String
    let userId: String
    let templateId: String?
    let templateName: String
    let date: Timestamp
    let duration: Double // TimeInterval yerine Double kullanıyoruz çünkü TimeInterval zaten Double'dır
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
    
    // Codable protokolü için özel kodlama/çözümleme
    enum CodingKeys: String, CodingKey {
        case id, userId, templateId, templateName, date, duration, totalWeight, caloriesBurned, exercises
    }
    
    init(id: String, userId: String, templateId: String?, templateName: String, 
         date: Timestamp, duration: Double, totalWeight: Double, caloriesBurned: Double, 
         exercises: [HistoryExercise]) {
        self.id = id
        self.userId = userId
        self.templateId = templateId
        self.templateName = templateName
        self.date = date
        self.duration = duration
        self.totalWeight = totalWeight
        self.caloriesBurned = caloriesBurned
        self.exercises = exercises
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
