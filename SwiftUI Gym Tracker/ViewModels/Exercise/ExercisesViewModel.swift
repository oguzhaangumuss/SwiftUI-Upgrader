import SwiftUI
import FirebaseFirestore

class ExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var selectedMuscleGroup: MuscleGroup? = nil
    @Published var muscleGroups: [MuscleGroup] = []
    
    init() {
        Task {
            await fetchExercises()
        }
        fetchMuscleGroups()
    }
    
    // Async olmayan wrapper metodu
    func fetchExercisesWrapper() {
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
    
    func fetchMuscleGroups() {
        muscleGroups = MuscleGroup.allCases
    }
} 
