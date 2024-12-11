import SwiftUI
import FirebaseFirestore

class WorkoutPlanViewModel: ObservableObject {
    @Published var workouts: [UserExercise] = []
    @Published var isLoading = false
    
    private let db = FirebaseManager.shared.firestore
    
    init() {
        Task {
            await fetchWorkouts(for: Date())
        }
    }
    
    @MainActor
    func fetchWorkouts(for date: Date) async {
        isLoading = true
        workouts = [] // Mevcut listeyi temizle
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            // 1. Antrenmanları getir
            let snapshot = try await db.collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            
            // 2. Egzersiz ID'lerini topla
            let exerciseIds = Set(snapshot.documents.compactMap { doc -> String? in
                guard let workout = try? doc.data(as: UserExercise.self) else { return nil }
                return workout.exerciseId
            })
            
            // 3. Egzersiz isimlerini tek seferde getir
            let exerciseNames = try await fetchExerciseNames(Array(exerciseIds))
            
            // 4. Antrenmanları oluştur
            var exercises: [UserExercise] = []
            for document in snapshot.documents {
                if var workout = try? document.data(as: UserExercise.self) {
                    workout.exerciseName = exerciseNames[workout.exerciseId]
                    exercises.append(workout)
                }
            }
            
            workouts = exercises.sorted { $0.date.dateValue() > $1.date.dateValue() }
            
        } catch {
            print("❌ Antrenmanlar getirilemedi: \(error)")
        }
        
        isLoading = false
    }
    
    private func fetchExerciseNames(_ exerciseIds: [String]) async throws -> [String: String] {
        var names: [String: String] = [:]
        
        // Firestore'un "in" operatörü için 10'lu gruplar halinde böl
        let chunks = exerciseIds.chunked(into: 10)
        
        for chunk in chunks {
            let snapshot = try await db.collection("exercises")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            for doc in snapshot.documents {
                names[doc.documentID] = doc.data()["name"] as? String
            }
        }
        
        return names
    }
    
    @MainActor
    func deleteWorkout(at indexSet: IndexSet) async {
        for index in indexSet {
            guard let workoutId = workouts[index].id else { continue }
            
            do {
                try await db.collection("userExercises").document(workoutId).delete()
                workouts.remove(at: index)
            } catch {
                print("Antrenman silinemedi: \(error)")
            }
        }
    }
} 
