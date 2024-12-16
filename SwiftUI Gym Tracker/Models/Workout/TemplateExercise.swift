import Foundation

struct TemplateExercise: Identifiable, Codable, Equatable {
    let id: String
    let exerciseId: String
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var notes: String?
    
    // Equatable protokolü için gerekli
    static func == (lhs: TemplateExercise, rhs: TemplateExercise) -> Bool {
        lhs.id == rhs.id &&
        lhs.exerciseId == rhs.exerciseId &&
        lhs.exerciseName == rhs.exerciseName &&
        lhs.sets == rhs.sets &&
        lhs.reps == rhs.reps &&
        lhs.weight == rhs.weight &&
        lhs.notes == rhs.notes
    }
} 