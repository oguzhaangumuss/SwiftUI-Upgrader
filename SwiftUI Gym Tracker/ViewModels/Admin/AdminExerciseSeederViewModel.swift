import SwiftUI
import FirebaseFirestore

class AdminExerciseSeederViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successCount = 0
    
    private let db = FirebaseManager.shared.firestore
    
    @MainActor
    func seedExercises() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid,
              let user = FirebaseManager.shared.currentUser,
              user.isAdmin else {
            errorMessage = "Bu işlem için admin yetkisi gerekiyor"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successCount = 0
        
        do {
            let exerciseData = try Bundle.main.decode(ExerciseData.self, from: "exercises")
            
            // Batch işlemi için
            let batch = db.batch()
            
            for exercise in exerciseData.exercises {
                let docRef = db.collection("exercises").document()
                batch.setData(exercise.toExercise(createdBy: userId), forDocument: docRef)
                successCount += 1
            }
            
            try await batch.commit()
            
        } catch BundleError.fileNotFound {
            errorMessage = "exercises.json dosyası bulunamadı"
        } catch {
            errorMessage = "Egzersizler eklenirken hata oluştu: \(error.localizedDescription)"
            successCount = 0
        }
        
        isLoading = false
    }
} 