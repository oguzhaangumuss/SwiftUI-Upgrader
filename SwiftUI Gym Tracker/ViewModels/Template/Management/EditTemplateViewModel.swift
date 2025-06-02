import SwiftUI
import FirebaseFirestore

class EditTemplateViewModel: ObservableObject {
    @Published var name: String
    @Published var notes: String
    @Published var exercises: [TemplateExercise]
    @Published var selectedGroupId: String?
    @Published var availableGroups: [WorkoutTemplateGroup] = []
    private let templateId: String
    
    var isValid: Bool {
        !name.isEmpty && !exercises.isEmpty && selectedGroupId != nil
    }
    
    init(template: WorkoutTemplate) {
        self.templateId = template.id ?? ""
        self.name = template.name
        self.notes = template.notes ?? ""
        self.exercises = template.exercises
        self.selectedGroupId = template.groupId
        
        Task {
            await fetchGroups()
        }
    }
    
    @MainActor
    private func fetchGroups() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            availableGroups = snapshot.documents.compactMap { doc in
                let data = doc.data()
                
                guard let name = data["name"] as? String else {
                    print("❌ Grup adı bulunamadı: \(doc.documentID)")
                    return nil
                }
                return WorkoutTemplateGroup(
                    id: doc.documentID,
                    userId: userId,
                    name: name,
                    createdAt: Timestamp(),
                    updatedAt: Timestamp()
                )
            }
        } catch {
            print("Gruplar yüklenemedi: \(error)")
        }
    }
    
    @MainActor
    func saveTemplate() async {
        guard let groupId = selectedGroupId else { return }
        
        do {
            let data: [String: Any] = [
                "name": name,
                "notes": notes,
                "exercises": exercises.map { exercise in
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
                "groupId": groupId,
                "updatedAt": Timestamp()
            ]
            
            try await FirebaseManager.shared.firestore
                .collection("workoutTemplates")
                .document(templateId)
                .updateData(data)
            
        } catch {
            print("Şablon güncellenirken hata: \(error)")
        }
    }
} 
