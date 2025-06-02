import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var userId: String
    var templateId: String?
    var templateName: String
    var date: Timestamp
    var duration: Double
    var totalWeight: Double
    var caloriesBurned: Double
    var notes: String?
    var createdAt: Timestamp
    var exercises: [WorkoutExercise]
    
    struct WorkoutExercise: Identifiable, Codable, Equatable {
        let id: String
        let exerciseId: String
        var exerciseName: String
        var sets: Int
        var reps: Int
        var weight: Double
        var notes: String?
        
        static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
            lhs.id == rhs.id &&
            lhs.exerciseId == rhs.exerciseId &&
            lhs.exerciseName == rhs.exerciseName &&
            lhs.sets == rhs.sets &&
            lhs.reps == rhs.reps &&
            lhs.weight == rhs.weight &&
            lhs.notes == rhs.notes
        }
    }
    
    init(
        id: String? = nil,
        name: String,
        userId: String,
        templateId: String? = nil,
        templateName: String,
        date: Date,
        duration: Double,
        totalWeight: Double,
        caloriesBurned: Double,
        notes: String? = nil,
        createdAt: Date = Date(),
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id ?? UUID().uuidString
        self.name = name
        self.userId = userId
        self.templateId = templateId
        self.templateName = templateName
        self.date = Timestamp(date: date)
        self.duration = duration
        self.totalWeight = totalWeight
        self.caloriesBurned = caloriesBurned
        self.notes = notes
        self.createdAt = Timestamp(date: createdAt)
        self.exercises = exercises
    }
    
    // Simple init for backward compatibility
    init(
        name: String,
        sets: Int,
        reps: Int,
        weight: Double,
        date: Date,
        notes: String,
        duration: Int,
        caloriesBurned: Int,
        exerciseId: String
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.userId = FirebaseManager.shared.auth.currentUser?.uid ?? ""
        self.templateId = nil
        self.templateName = name
        self.date = Timestamp(date: date)
        self.duration = Double(duration)
        self.totalWeight = weight * Double(sets)
        self.caloriesBurned = Double(caloriesBurned)
        self.notes = notes
        self.createdAt = Timestamp(date: Date())
        
        let exercise = WorkoutExercise(
            id: UUID().uuidString,
            exerciseId: exerciseId,
            exerciseName: name,
            sets: sets,
            reps: reps,
            weight: weight,
            notes: nil
        )
        self.exercises = [exercise]
    }
}

extension Workout {
    func toWorkoutHistory() -> WorkoutHistory {
        let historyExercises = exercises.map { exercise in
            WorkoutHistory.HistoryExercise(
                id: exercise.id,
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                sets: exercise.sets,
                weight: exercise.weight
            )
        }
        
        return WorkoutHistory(
            id: id ?? UUID().uuidString,
            userId: userId,
            templateId: templateId,
            templateName: templateName,
            date: date,
            duration: duration,
            totalWeight: totalWeight,
            caloriesBurned: caloriesBurned,
            exercises: historyExercises
        )
    }
} 