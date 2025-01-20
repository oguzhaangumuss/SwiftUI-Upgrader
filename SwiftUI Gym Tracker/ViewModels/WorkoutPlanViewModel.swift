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
    
    private let db = FirebaseManager.shared.firestore
    
    @MainActor
    func fetchTemplates() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
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
            
        } catch {
            errorMessage = "Şablonlar yüklenirken bir hata oluştu"
            print("❌ Şablon yükleme hatası: \(error)")
        }
    }
    
    func deleteGroup(_ group: WorkoutTemplateGroup) async {
        guard let groupId = group.id else { return }
        
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
        } catch {
            print("Grup ismi güncellenemedi: \(error.localizedDescription)")
        }
    }
} 
