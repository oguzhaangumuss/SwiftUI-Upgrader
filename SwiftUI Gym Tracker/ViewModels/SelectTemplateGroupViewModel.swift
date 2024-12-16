import SwiftUI
import FirebaseFirestore

class SelectTemplateGroupViewModel: ObservableObject {
    @Published var groups: [WorkoutTemplateGroup] = []
    @Published var isLoading = false
    
    private let db = FirebaseManager.shared.firestore
    
    func fetchGroups() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            let snapshot = try await db.collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let fetchedGroups = snapshot.documents.compactMap { try? $0.data(as: WorkoutTemplateGroup.self) }
            
            await MainActor.run {
                self.groups = fetchedGroups
                self.isLoading = false
            }
        } catch {
            print("❌ Gruplar yüklenemedi: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
} 