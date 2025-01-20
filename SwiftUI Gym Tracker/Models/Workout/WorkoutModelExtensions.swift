import Foundation

extension Exercise {
    func toActiveWorkoutExercise() -> ActiveWorkoutExercise {
        return ActiveWorkoutExercise(
            exerciseId: self.id ?? "",
            exerciseName: self.name
        )
    }
}

extension TemplateExercise {
    func toActiveWorkoutExercise() -> ActiveWorkoutExercise {
        // Önce egzersizi oluştur
        var exercise = ActiveWorkoutExercise(
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
                    weight: self.weight ?? 0,
                    reps: self.reps,
                    isCompleted: false
                )
            )
        }
        
        return exercise
    }
}

extension ActiveWorkoutExercise {
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