import SwiftUI
import FirebaseFirestore

class RenameGroupViewModel: ObservableObject {
    @Published var name: String
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let groupId: String?
    
    init(group: WorkoutTemplateGroup) {
        self.groupId = group.id
        self.name = group.name
    }
    
    @MainActor
    func saveGroupName() async -> Bool {
        guard let groupId = groupId,
              !name.isEmpty else { return false }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data: [String: Any] = [
                "name": name,
                "updatedAt": Timestamp()
            ]
            
            try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .document(groupId)
                .updateData(data)
            
            NotificationCenter.default.post(name: .templateGroupRenamed, object: nil)
            return true
            
        } catch {
            errorMessage = "Grup adı güncellenemedi: \(error.localizedDescription)"
            return false
        }
    }
} 
