import SwiftUI
import FirebaseFirestore

class ActiveWorkoutViewModel: ObservableObject {
    @Published var exercises: [ActiveExercise] = []
    @Published var selectedTemplate: WorkoutTemplate?
    @Published var progress: [String: ExerciseProgress] = [:]
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = FirebaseManager.shared.firestore
    
    func loadTemplate(_ template: WorkoutTemplate) {
        selectedTemplate = template
        exercises = template.exercises.map { templateExercise in
            ActiveExercise(
                id: UUID().uuidString,
                exerciseId: templateExercise.exerciseId,
                name: templateExercise.exerciseName,
                sets: Array(repeating: ExerciseSet(
                    reps: templateExercise.reps,
                    weight: templateExercise.weight ?? 0,
                    isCompleted: false
                ), count: templateExercise.sets),
                notes: templateExercise.notes
            )
        }
    }
    
    func updateProgress(for exerciseId: String, progress: ExerciseProgress) {
        self.progress[exerciseId] = progress
    }
    
    @MainActor
    func saveWorkout() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            for exercise in exercises {
                let exerciseProgress = progress[exercise.id] ?? .init()
                
                // Sadece en az bir set tamamlanmış egzersizleri kaydet
                guard !exerciseProgress.completedSets.isEmpty else { continue }
                
                let exerciseData: [String: Any] = [
                    "userId": userId,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.name,
                    "sets": exerciseProgress.completedSets.count,
                    "reps": exerciseProgress.completedSets.first?.reps ?? 0,
                    "weight": exerciseProgress.completedSets.first?.weight ?? 0,
                    "date": Timestamp(),
                    "notes": exercise.notes ?? "",
                    "duration": 0, // Varsayılan süre
                    "createdAt": Timestamp()
                ]
                
                try await db.collection("userExercises")
                    .addDocument(data: exerciseData)
            }
        } catch {
            errorMessage = "Antrenman kaydedilemedi"
            print("❌ Antrenman kaydetme hatası: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchWorkoutTemplates(for template: WorkoutTemplate) {
        // ... implementation ...
    }
}



