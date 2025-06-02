import FirebaseFirestore
import Foundation

/// Egzersiz seti modeli
struct WorkoutSet: Identifiable, Equatable {
    let id = UUID()
    var setNumber: Int
    var previousBest: Double? // Geçmiş en iyi ağırlık
    var weight: Double
    var reps: Int
    var isCompleted: Bool = false
    
    static func == (lhs: WorkoutSet, rhs: WorkoutSet) -> Bool {
        lhs.id == rhs.id &&
        lhs.setNumber == rhs.setNumber &&
        lhs.previousBest == rhs.previousBest &&
        lhs.weight == rhs.weight &&
        lhs.reps == rhs.reps &&
        lhs.isCompleted == rhs.isCompleted
    }
} 