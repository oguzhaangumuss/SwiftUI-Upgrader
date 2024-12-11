import FirebaseFirestore

protocol ExerciseService {
    func fetchExercises() async throws -> [Exercise]
    func updateExercise(_ exercise: Exercise) async throws
    func deleteExercise(_ id: String) async throws
}

class FirebaseExerciseService: ExerciseService {
    private let db = FirebaseManager.shared.firestore
    
    func fetchExercises() async throws -> [Exercise] {
        let snapshot = try await db.collection("exercises").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Exercise.self) }
    }
    
    func updateExercise(_ exercise: Exercise) async throws {
        guard let id = exercise.id else { throw ExerciseError.updateFailed }
        try await db.collection("exercises").document(id).setData(from: exercise)
    }
    
    func deleteExercise(_ id: String) async throws {
        try await db.collection("exercises").document(id).delete()
    }
} 