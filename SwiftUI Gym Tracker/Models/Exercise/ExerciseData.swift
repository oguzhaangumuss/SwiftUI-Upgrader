import Foundation

struct ExerciseData: Codable {
    let exercises: [ExerciseItem]
}

struct ExerciseItem: Codable {
    let name: String
    let description: String
    let muscleGroups: [String]
    let metValue: Double
    
    func toExercise(createdBy: String) -> [String: Any] {
        return [
            "name": name,
            "description": description,
            "muscleGroups": muscleGroups.compactMap { rawValue in
                MuscleGroup.allCases.first { $0.rawValue == rawValue }?.rawValue
            },
            "metValue": metValue,
            "createdBy": createdBy,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "averageRating": 0.0,
            "totalRatings": 0
        ]
    }
} 