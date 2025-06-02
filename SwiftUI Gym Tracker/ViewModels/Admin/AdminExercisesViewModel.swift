import SwiftUI
import FirebaseFirestore

class AdminExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    
    init() {
        Task {
            await fetchExercises()
        }
    }
    
    @MainActor
    func fetchExercises() async {
        isLoading = true
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("exercises")
                .getDocuments()
            
            exercises = snapshot.documents.compactMap { try? $0.data(as: Exercise.self) }
        } catch {
            print("Egzersizler getirilemedi: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func addExercise(name: String, description: String, muscleGroups: Set<MuscleGroup>) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let exerciseData: [String: Any] = [
            "name": name,
            "description": description,
            "muscleGroups": Array(muscleGroups).map { $0.rawValue },
            "createdBy": userId,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "averageRating": 0.0,
            "totalRatings": 0,
            "metValue": NSNull()
        ]
        
        do {
            try await FirebaseManager.shared.firestore
                .collection("exercises")
                .document()
                .setData(exerciseData)
            
            await fetchExercises()
        } catch {
            print("Egzersiz eklenemedi: \(error)")
        }
    }
    
    @MainActor
    func deleteExercises(at indexSet: IndexSet) async {
        for index in indexSet {
            let exercise = exercises[index]
            await deleteExercise(exercise)
        }
    }
    
    @MainActor
    func deleteExercise(_ exercise: Exercise) async {
        guard let exerciseId = exercise.id else { return }
        
        do {
            try await FirebaseManager.shared.firestore
                .collection("exercises")
                .document(exerciseId)
                .delete()
            
            if let index = exercises.firstIndex(where: { $0.id == exerciseId }) {
                exercises.remove(at: index)
            }
        } catch {
            print("Egzersiz silinemedi: \(error)")
        }
    }
} 