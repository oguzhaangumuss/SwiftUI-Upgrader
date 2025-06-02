import Foundation

/// Model dönüşüm extension'ları
/// Bu dosya farklı modeller arasındaki dönüşüm extension'larını içerir

// MARK: - Exercise -> ActiveExercise
extension Exercise {
    func toActiveExercise() -> ActiveExercise {
        return ActiveExercise(
            exerciseId: self.id ?? "",
            exerciseName: self.name
        )
    }
}

// MARK: - TemplateExercise -> ActiveExercise
extension TemplateExercise {
    func toActiveExercise() -> ActiveExercise {
        // Önce egzersizi oluştur
        var exercise = ActiveExercise(
            exerciseId: self.exerciseId,
            exerciseName: self.exerciseName
        )
        
        // Mevcut setleri temizle ve yeniden oluştur
        exercise.sets = []
        
        // Tüm setleri oluştur
        for i in 0..<self.sets {
            exercise.sets.append(
                WorkoutSet(
                    setNumber: i + 1,
                    previousBest: nil,
                    weight: self.weight,
                    reps: self.reps,
                    isCompleted: false
                )
            )
        }
        
        return exercise
    }
}

// MARK: - ActiveExercise -> TemplateExercise
extension ActiveExercise {
    func toTemplateExercise() -> TemplateExercise {
        return TemplateExercise(
            id: self.id.uuidString,
            exerciseId: self.exerciseId,
            exerciseName: self.exerciseName,
            sets: self.sets.count,
            reps: self.sets.first?.reps ?? 0,
            weight: self.sets.first?.weight ?? 0
        )
    }
} 