import SwiftUI
import FirebaseFirestore

class TemplateGroupsViewModel: ObservableObject {
    @Published var templateGroups: [WorkoutTemplateGroup] = []
    @Published var templates: [String: [WorkoutTemplate]] = [:]
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = FirebaseManager.shared.firestore
    
    @MainActor
    func fetchTemplates() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            print("🔍 Şablonlar yükleniyor...")
            print("👤 User ID: \(userId)")
            
            // Önce grupları çekelim
            let groupsSnapshot = try await db.collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            print("📁 Bulunan grup sayısı: \(groupsSnapshot.documents.count)")
            
            // Grupları işleyelim
            var updatedGroups: [WorkoutTemplateGroup] = []
            for groupDoc in groupsSnapshot.documents {
                if let group = try? groupDoc.data(as: WorkoutTemplateGroup.self) {
                    print("📁 Grup bulundu: \(group.name) (ID: \(groupDoc.documentID))")
                    
                    // Her grup için şablonları çekelim
                    let templatesSnapshot = try await db.collection("workoutTemplates")
                        .whereField("groupId", isEqualTo: groupDoc.documentID)
                        .whereField("userId", isEqualTo: userId)
                        .getDocuments()
                    
                    print("📝 \(templatesSnapshot.documents.count) şablon bulundu - Grup: \(group.name)")
                    
                    let templates = templatesSnapshot.documents.compactMap { doc -> WorkoutTemplate? in
                        do {
                            let template = try doc.data(as: WorkoutTemplate.self)
                            print("✅ Şablon yüklendi: \(template.name)")
                            return template
                        } catch {
                            print("❌ Şablon yüklenemedi: \(error)")
                            return nil
                        }
                    }
                    
                    updatedGroups.append(group)
                    self.templates[groupDoc.documentID] = templates
                }
            }
            
            self.templateGroups = updatedGroups
            
        } catch {
            print("❌ Şablon yükleme hatası: \(error)")
            self.errorMessage = "Şablonlar yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        self.isLoading = false
    }
    
    // Yeni şablon grubu oluşturma
    func createTemplateGroup(name: String) async throws {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış"])
        }
        
        let groupData: [String: Any] = [
            "userId": userId,
            "name": name,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        try await db.collection("templateGroups").addDocument(data: groupData)
        await fetchTemplates()
    }
    
    // Şablon grubunu silme
    func deleteTemplateGroup(_ group: WorkoutTemplateGroup) async throws {
        guard let groupId = group.id else { return }
        
        // Önce gruptaki tüm şablonları sil
        let templatesSnapshot = try await db.collection("workoutTemplates")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments()
        
        for doc in templatesSnapshot.documents {
            try await doc.reference.delete()
        }
        
        // Sonra grubu sil
        try await db.collection("templateGroups").document(groupId).delete()
        await fetchTemplates()
    }
} 