import SwiftUI
import FirebaseFirestore

class ExercisesViewModel: ObservableObject {
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
} 
