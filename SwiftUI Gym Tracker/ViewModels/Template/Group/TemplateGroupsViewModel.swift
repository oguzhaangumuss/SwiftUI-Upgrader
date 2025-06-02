import SwiftUI
import FirebaseFirestore

class TemplateGroupsViewModel: ObservableObject {
    // MARK: - Properties
    @Published var groups: [WorkoutTemplateGroup] = []
    @Published var templates: [String: [WorkoutTemplate]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseManager.shared.firestore
    
    // MARK: - Group Operations
    
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
            errorMessage = "Gruplar yüklenirken hata oluştu: \(error.localizedDescription)"
            print("Error fetching groups: \(error)")
        }
    }
    
    @MainActor
    func createGroup(name: String) async throws -> String {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturum açmamış"])
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
    
    // RenameGroupViewModel'den eklenen metod
    @MainActor
    func renameGroup(groupId: String, newName: String) async -> Bool {
        guard !newName.isEmpty else { return false }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data: [String: Any] = [
                "name": newName,
                "updatedAt": Timestamp()
            ]
            
            try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .document(groupId)
                .updateData(data)
            
            // Yerel veriyi de güncelle
            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index].name = newName
            }
            
            NotificationCenter.default.post(name: .templateGroupRenamed, object: nil)
            return true
            
        } catch {
            errorMessage = "Grup adı güncellenemedi: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Template Operations
    
    @MainActor
    func fetchTemplates() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { 
            print("❌ fetchTemplates: Kullanıcı oturum açmamış")
            return 
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            debugPrint("Şablonlar getirilmeye başlandı - UserId: \(userId)")
            
            var fetchedTemplates: [String: [WorkoutTemplate]] = [:]
            
            // For each group, fetch its templates specifically
            for group in groups {
                guard let groupId = group.id else { continue }
                
                let templatesSnapshot = try await FirebaseManager.shared.firestore
                    .collection("workoutTemplates")
                    .whereField("groupId", isEqualTo: groupId)
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                
                let groupTemplates = templatesSnapshot.documents.compactMap { doc -> WorkoutTemplate? in
                    var template = try? doc.data(as: WorkoutTemplate.self)
                    template?.id = doc.documentID
                    return template
                }
                
                fetchedTemplates[groupId] = groupTemplates
                debugPrint("Grup: \(group.name) (\(groupId)) - Şablon Sayısı: \(groupTemplates.count)")
            }
            
            // Update the templates property
            self.templates = fetchedTemplates
            
        } catch {
            errorMessage = "Şablonlar yüklenirken hata oluştu: \(error.localizedDescription)"
            print("❌ Şablonlar yüklenirken hata: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    func fetchAll() async {
        await fetchGroups()
        await fetchTemplates()
    }
    
    // Grup silme işlevi
    @MainActor
    func deleteGroup(_ groupId: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Önce gruptaki tüm şablonları sil
            if let groupTemplates = templates[groupId] {
                for template in groupTemplates {
                    if let templateId = template.id {
                        try await FirebaseManager.shared.firestore
                            .collection("workoutTemplates")
                            .document(templateId)
                            .delete()
                    }
                }
            }
            
            // Sonra grubu sil
            try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .document(groupId)
                .delete()
            
            // Yerel verileri güncelle
            templates.removeValue(forKey: groupId)
            groups.removeAll { $0.id == groupId }
            
            return true
        } catch {
            errorMessage = "Grup silinirken hata oluştu: \(error.localizedDescription)"
            print("❌ Grup silinirken hata: \(error.localizedDescription)")
            return false
        }
    }
} 
