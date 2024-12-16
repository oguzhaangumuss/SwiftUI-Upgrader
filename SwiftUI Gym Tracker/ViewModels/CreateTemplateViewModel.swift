import SwiftUI
import FirebaseFirestore

class CreateTemplateViewModel: ObservableObject {
    @Published var selectedExercises: [TemplateExercise] = []
    @Published var previousBests: [String: PreviousBest] = [:]
    @Published var isLoading = false
    @Published var groups: [WorkoutTemplateGroup] = []
    
    private let db = FirebaseManager.shared.firestore
    
    init() {
        Task {
            await fetchGroups()
        }
    }
    
    @MainActor
    private func fetchGroups() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: false)
                .getDocuments()
            
            groups = snapshot.documents.compactMap { try? $0.data(as: WorkoutTemplateGroup.self) }
            print("📁 Yüklenen gruplar: \(groups.map { "\($0.name) (\($0.id ?? ""))" }.joined(separator: ", "))")
        } catch {
            print("❌ Gruplar yüklenemedi: \(error)")
        }
    }
    
    @MainActor
    func fetchPreviousBests(for exercises: [TemplateExercise]) async {
        for exercise in exercises {
            if previousBests[exercise.exerciseId] == nil {
                if let best = await getPreviousBest(for: exercise.exerciseId) {
                    previousBests[exercise.exerciseId] = best
                }
            }
        }
    }
    
    @MainActor
    func saveTemplate(name: String, notes: String, groupId: String) async throws {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış"])
        }
        
        let templateData: [String: Any] = [
            "name": name,
            "notes": notes,
            "exercises": selectedExercises.map { exercise in
                [
                    "id": exercise.id,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.exerciseName,
                    "sets": exercise.sets,
                    "reps": exercise.reps,
                    "weight": exercise.weight as Any,
                    "notes": exercise.notes as Any
                ]
            },
            "createdBy": userId,
            "userId": userId,
            "groupId": groupId,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        print("💾 Şablon kaydediliyor...")
        print("📝 Template Data: \(templateData)")
        
        try await db.collection("workoutTemplates")
            .addDocument(data: templateData)
        
        print("✅ Şablon başarıyla kaydedildi")
    }
    
    func getPreviousBest(for exerciseId: String) async -> PreviousBest? {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return nil }
        
        do {
            let snapshot = try await db.collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .whereField("exerciseId", isEqualTo: exerciseId)
                .order(by: "weight", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let doc = snapshot.documents.first,
               let exercise = try? doc.data(as: UserExercise.self) {
                return PreviousBest(
                    weight: exercise.weight,
                    reps: exercise.reps,
                    date: exercise.date.dateValue()
                )
            }
        } catch {
            print("❌ Geçmiş performans getirilemedi: \(error)")
        }
        
        return nil
    }
} 
