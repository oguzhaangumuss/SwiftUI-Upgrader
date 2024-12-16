import Foundation

struct TemplateExercise: Codable, Identifiable {
    var id: String
    var exerciseId: String
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double?
    var notes: String?
} 