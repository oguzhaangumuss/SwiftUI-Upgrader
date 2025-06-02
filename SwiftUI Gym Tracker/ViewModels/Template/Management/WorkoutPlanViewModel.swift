import SwiftUI
import FirebaseFirestore
import Foundation

protocol WorkoutPlanDelegate: AnyObject {
    func templateDidDelete()
}

class WorkoutPlanViewModel: ObservableObject, WorkoutPlanDelegate {
    @Published var templateGroups: [WorkoutTemplateGroup] = []
    @Published var templates: [String: [WorkoutTemplate]] = [:]
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // Add templateGroupsViewModel for use with TemplateGroupView
    let templateGroupsViewModel = TemplateGroupsViewModel()
    
    // Aliases to match what WorkoutPlanView is expecting
    var groups: [TemplateGroup] { templateGroups }
    
    private let db = FirebaseManager.shared.firestore
    
    @MainActor
    func fetchTemplates() async {
        isLoading = true
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { 
            isLoading = false
            return 
        }
        
        do {
            // Önce grupları getir
            let groupsSnapshot = try await db.collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            templateGroups = groupsSnapshot.documents.compactMap { try? $0.data(as: WorkoutTemplateGroup.self) }
            
            // Her grup için şablonları getir
            for group in templateGroups {
                guard let groupId = group.id else { continue }
                
                let templatesSnapshot = try await db.collection("workoutTemplates")
                    .whereField("groupId", isEqualTo: groupId)
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                
                let groupTemplates = templatesSnapshot.documents.compactMap { try? $0.data(as: WorkoutTemplate.self) }
                templates[groupId] = groupTemplates
                
                print("📁 \(group.name) grubu için \(groupTemplates.count) şablon yüklendi")
            }
            
            // Sync data with templateGroupsViewModel
            templateGroupsViewModel.groups = templateGroups
            templateGroupsViewModel.templates = templates
            
        } catch {
            errorMessage = "Şablonlar yüklenirken bir hata oluştu"
            print("❌ Şablon yükleme hatası: \(error)")
        }
        
        isLoading = false
    }
    
    // Alias method for fetchTemplates to match what WorkoutPlanView is expecting
    @MainActor
    func fetchAllGroups() async {
        await fetchTemplates()
    }
    
    // Method to add a new group
    @MainActor
    func addGroup(name: String) async {
        guard !name.isEmpty else {
            errorMessage = "Grup adı boş olamaz"
            return
        }
        
        isLoading = true
        
        do {
            guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
                isLoading = false
                return
            }
            
            let newGroup: [String: Any] = [
                "name": name,
                "userId": userId,
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ]
            
            let docRef = try await db.collection("templateGroups").addDocument(data: newGroup)
            print("✅ Yeni grup oluşturuldu: \(docRef.documentID)")
            
            // Refresh groups
            await fetchTemplates()
            
            // Sync with templateGroupsViewModel
            await templateGroupsViewModel.fetchAll()
        } catch {
            errorMessage = "Grup oluşturulurken bir hata oluştu"
            print("❌ Grup oluşturma hatası: \(error)")
        }
        
        isLoading = false
    }
    
    // Alias method for renameGroup to updateGroupName
    @MainActor
    func renameGroup(id: String, newName: String) async {
        await updateGroupName(id, newName: newName)
    }
    
    // Overload deleteGroup for TemplateGroup
    @MainActor
    func deleteGroup(id: String) async {
        if let group = templateGroups.first(where: { $0.id == id }) {
            await deleteGroup(group)
            
            // Sync with templateGroupsViewModel
            _ = await templateGroupsViewModel.deleteGroup(id)
        }
    }
    
    func deleteGroup(_ group: WorkoutTemplateGroup) async {
        guard let groupId = group.id else { return }
        
        isLoading = true
        
        do {
            // Önce gruptaki tüm şablonları sil
            if let templates = templates[groupId] {
                for template in templates {
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
            
            // UI'ı güncelle
            await fetchTemplates()
            
        } catch {
            print("❌ Grup silinirken hata: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func templateDidDelete() {
        Task {
            await fetchTemplates()
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) async {
        guard let templateId = template.id else { return }
        
        do {
            try await FirebaseManager.shared.firestore
                .collection("workoutTemplates")
                .document(templateId)
                .delete()
            
            // UI'ı güncelle
            await MainActor.run {
                if let groupId = template.groupId {
                    templates[groupId]?.removeAll { $0.id == template.id }
                    
                    // Sync with templateGroupsViewModel
                    templateGroupsViewModel.templates[groupId]?.removeAll { $0.id == template.id }
                }
            }
            
            print("✅ Şablon başarıyla silindi")
        } catch {
            print("❌ Şablon silinirken hata: \(error.localizedDescription)")
        }
    }
    
    func updateGroupName(_ groupId: String, newName: String) async {
        do {
            try await FirebaseManager.shared.firestore
                .collection("templateGroups")
                .document(groupId)
                .updateData(["name": newName])
            
            // UI'ı güncelle
            if let index = templateGroups.firstIndex(where: { $0.id == groupId }) {
                templateGroups[index].name = newName
            }
            
            // Sync with templateGroupsViewModel
            _ = await templateGroupsViewModel.renameGroup(groupId: groupId, newName: newName)
        } catch {
            print("Grup ismi güncellenemedi: \(error.localizedDescription)")
        }
    }
    
    // Method to get templates for a specific group
    func getTemplatesForGroup(groupId: String) -> [WorkoutTemplate] {
        return templates[groupId] ?? []
    }
} 
