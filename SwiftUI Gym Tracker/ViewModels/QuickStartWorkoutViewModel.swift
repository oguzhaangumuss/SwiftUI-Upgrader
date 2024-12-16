import SwiftUI
import FirebaseFirestore

class QuickStartWorkoutViewModel: ObservableObject {
    @Published var selectedExercises: [TemplateExercise] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = FirebaseManager.shared.firestore
    
    func removeExercise(_ exercise: TemplateExercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
    }
    
    @MainActor
    func startWorkout(notes: String) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Her egzersiz için bir UserExercise oluştur
            for exercise in selectedExercises {
                let exerciseData: [String: Any] = [
                    "userId": userId,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.exerciseName,
                    "sets": exercise.sets,
                    "reps": exercise.reps,
                    "weight": exercise.weight ?? 0,
                    "date": Timestamp(),
                    "notes": exercise.notes ?? "",
                    "duration": 0, // Varsayılan süre
                    "createdAt": Timestamp()
                ]
                
                try await db.collection("userExercises")
                    .addDocument(data: exerciseData)
            }
        } catch {
            errorMessage = "Antrenman başlatılamadı"
            print("❌ Antrenman başlatma hatası: \(error)")
        }
        
        isLoading = false
    }
} 
