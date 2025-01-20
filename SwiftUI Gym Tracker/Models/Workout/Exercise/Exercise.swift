import FirebaseFirestore

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Göğüs"
    case back = "Sırt"
    case legs = "Bacak"
    case shoulders = "Omuz"
    case arms = "Kol"
    case core = "Karın"
    case cardio = "Kardiyo"
    case fullBody = "Tam Vücut"
}

struct Exercise: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let muscleGroups: [MuscleGroup]
    let createdBy: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    var averageRating: Double?
    var totalRatings: Int
    let metValue: Double?
    
    static var example: Exercise {
        Exercise(
            id: "example",
            name: "Bench Press",
            description: "Klasik göğüs egzersizi",
            muscleGroups: [.chest, .shoulders, .arms],
            createdBy: "admin",
            createdAt: Timestamp(),
            updatedAt: Timestamp(),
            averageRating: 4.5,
            totalRatings: 10,
            metValue: 3.8
        )
    }
}

extension Exercise {
    func calculateCalories(weight: Double, duration: TimeInterval) -> Double? {
        guard let metValue = metValue else { return nil }
        
        let hours = duration / 3600  // saniyeyi saate çevir
        return metValue * weight * hours
    }
}




struct WorkoutPlan: Identifiable, Codable {
    let id: String
    let date: Timestamp
    var exercises: [WorkoutExercise]
    let notes: String?
    let createdAt: Timestamp
    
    struct WorkoutExercise: Codable, Identifiable {
        let id: String
        let exerciseId: String
        var sets: Int
        var reps: Int
        var weight: Double
    }
}

// Progress modelleri
struct ExerciseSet: Identifiable {
    let id = UUID()
    var reps: Int
    var weight: Double
    var isCompleted: Bool
}

struct ActiveExercise: Identifiable {
    let id: String
    let exerciseId: String
    let name: String
    var sets: [ExerciseSet]
    var notes: String?
}



struct ExerciseProgress {
    var completedSets: [ExerciseSet] = []
    var currentSetIndex: Int = 0
}
