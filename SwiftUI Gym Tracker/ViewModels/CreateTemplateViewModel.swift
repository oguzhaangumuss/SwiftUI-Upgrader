import SwiftUI
import FirebaseFirestore

class CreateTemplateViewModel: ObservableObject {
    @Published var selectedExercises: [TemplateExercise] = []
    @Published var templateName: String = ""
    @Published var previousBests: [String: PreviousBest] = [:]
    @Published var isLoading = false
    @Published var groups: [WorkoutTemplateGroup] = []
    @Published var selectedGroupId: String = ""
    @Published var isGroupSelectionLocked: Bool = false
    
    private let db = FirebaseManager.shared.firestore
    
    init(groupId: String? = nil) {
        if let groupId = groupId {
            self.selectedGroupId = groupId
            self.isGroupSelectionLocked = true
        }
        
        Task {
            await fetchGroups()
        }
    }
    
    @MainActor
    func fetchGroups() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            self.groups = snapshot.documents.compactMap { document -> WorkoutTemplateGroup? in
                var group = try? document.data(as: WorkoutTemplateGroup.self)
                group?.id = document.documentID
                return group
            }
        } catch {
            print("Error fetching groups: \(error)")
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
    func saveTemplate(name: String) async throws {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış"])
        }
        
        guard !selectedGroupId.isEmpty else {
            throw NSError(domain: "", code: -2, 
                        userInfo: [NSLocalizedDescriptionKey: "Lütfen bir grup seçin"])
        }
        
        let templateData: [String: Any] = [
            "name": name,
            "exercises": selectedExercises.map { $0.toDictionary() },
            "createdBy": userId,
            "userId": userId,
            "groupId": selectedGroupId,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        try await db.collection("workoutTemplates")
            .addDocument(data: templateData)
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
    
    func removeExercise(_ exercise: TemplateExercise) {
        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
            selectedExercises.remove(at: index)
        }
    }
    
    func addExercise(_ exercise: Exercise) {
        let newExercise = TemplateExercise(
            id: UUID().uuidString,
            exerciseId: exercise.id ?? "",
            exerciseName: exercise.name,
            sets: 1,
            reps: 0,
            weight: 0
        )
        selectedExercises.append(newExercise)
    }
    
    var selectedGroupName: String {
        groups.first(where: { $0.id == selectedGroupId })?.name ?? "Seçilmedi"
    }
} 
