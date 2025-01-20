import SwiftUI
import FirebaseFirestore

class TemplateGroupsViewModel: ObservableObject {
    @Published var groups: [WorkoutTemplateGroup] = []
    @Published var templates: [String: [WorkoutTemplate]] = [:]
    @Published var isLoading = false
    
    @MainActor
    func fetchGroups() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let fetchedGroups = snapshot.documents.compactMap { document -> WorkoutTemplateGroup? in
                var group = try? document.data(as: WorkoutTemplateGroup.self)
                group?.id = document.documentID
                return group
            }
            
            self.groups = fetchedGroups
            
        } catch {
            print("Error fetching groups: \(error)")
        }
    }
    
    @MainActor
    func fetchTemplates() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("workoutTemplates")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            var templatesByGroup: [String: [WorkoutTemplate]] = [:]
            
            for document in snapshot.documents {
                if var template = try? document.data(as: WorkoutTemplate.self),
                   let groupId = template.groupId {
                    template.id = document.documentID
                    templatesByGroup[groupId, default: []].append(template)
                }
            }
            
            self.templates = templatesByGroup
            
        } catch {
            print("Error fetching templates: \(error)")
        }
    }

    // Grup oluşturma fonksiyonu
    @MainActor
    func createGroup(name: String) async throws -> String {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let data: [String: Any] = [
            "name": name,
            "userId": userId,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        let docRef = try await FirebaseManager.shared.firestore
            .collection("templateGroups")
            .addDocument(data: data)
        
        await fetchGroups()  // Grupları yenile
        return docRef.documentID
    }
    
    // Her iki veriyi de yükleyen yardımcı fonksiyon
    @MainActor
    func fetchAll() async {
        await fetchGroups()
        await fetchTemplates()
    }
} 