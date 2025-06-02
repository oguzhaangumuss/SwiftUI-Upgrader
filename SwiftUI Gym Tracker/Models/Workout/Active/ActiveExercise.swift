import FirebaseFirestore
import Foundation

/// Aktif antrenmandaki egzersiz modeli
struct ActiveExercise: Identifiable, Equatable {
    let id = UUID()
    let exerciseId: String
    let exerciseName: String
    var sets: [WorkoutSet]
    var notes: String?
    
    init(exerciseId: String, exerciseName: String) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = [WorkoutSet(setNumber: 1, previousBest: nil, weight: 0, reps: 0)]
    }
    
    mutating func addSet() {
        guard !sets.isEmpty else {
            let newSet = WorkoutSet(
                setNumber: 1,
                previousBest: nil,
                weight: 0,
                reps: 0,
                isCompleted: false
            )
            sets = [newSet]
            return
        }
        
        guard let lastSet = sets.last else { return }
        
        let newSet = WorkoutSet(
            setNumber: sets.count + 1,
            previousBest: nil,
            weight: lastSet.weight,
            reps: lastSet.reps,
            isCompleted: false
        )
        
        sets.append(newSet)
    }
    
    mutating func removeSet(at setNumber: Int) {
        sets.removeAll { $0.setNumber == setNumber }
        for i in 0..<sets.count {
            sets[i].setNumber = i + 1
        }
    }
    
    static func == (lhs: ActiveExercise, rhs: ActiveExercise) -> Bool {
        lhs.id == rhs.id &&
        lhs.exerciseId == rhs.exerciseId &&
        lhs.exerciseName == rhs.exerciseName &&
        lhs.sets == rhs.sets &&
        lhs.notes == rhs.notes
    }
} 