import SwiftUI
import FirebaseFirestore
import Foundation

class WorkoutPlanViewModel: ObservableObject {
    @Published var templateGroups: [WorkoutTemplateGroup] = []
    @Published var templates: [String: [WorkoutTemplate]] = [:]
    @Published var sampleTemplates: [WorkoutTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseManager.shared.firestore
    
    init() {
        Task {
            await fetchTemplateGroups()
            await fetchSampleTemplates()
        }
    }
    
    @MainActor
    func fetchTemplateGroups() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        do {
            // Önce varsayılan grubu kontrol et ve yoksa oluştur
            let defaultGroupRef = db.collection("templateGroups").document("default_\(userId)")
            let defaultGroup = try await defaultGroupRef.getDocument()
            
            if !defaultGroup.exists {
                let defaultGroupData: [String: Any] = [
                    "userId": userId,
                    "name": "Şablonlarım",
                    "createdAt": Timestamp(),
                    "updatedAt": Timestamp()
                ]
                try await defaultGroupRef.setData(defaultGroupData)
            }
            
            // Tüm grupları getir
            let snapshot = try await db.collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            templateGroups = snapshot.documents.compactMap { try? $0.data(as: WorkoutTemplateGroup.self) }
            
            // Her grup için şablonları getir
            for group in templateGroups {
                guard let groupId = group.id else { continue }
                
                let templatesSnapshot = try await db.collection("workoutTemplates")
                    .whereField("groupId", isEqualTo: groupId)
                    .getDocuments()
                
                templates[groupId] = templatesSnapshot.documents.compactMap { try? $0.data(as: WorkoutTemplate.self) }
            }
            
        } catch {
            errorMessage = "Şablonlar yüklenirken bir hata oluştu"
            print("❌ Şablon yükleme hatası: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchSampleTemplates() async {
        do {
            let snapshot = try await db.collection("sampleTemplates").getDocuments()
            sampleTemplates = snapshot.documents.compactMap { try? $0.data(as: WorkoutTemplate.self) }
        } catch {
            print("❌ Örnek şablonlar yüklenemedi: \(error)")
        }
    }
} 
