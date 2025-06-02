import Foundation
import FirebaseFirestore
import FirebaseAuth


/// Şablon grupları ve şablonlar için veri erişim katmanı
class TemplateRepository {
    private let db = FirebaseManager.shared.firestore
    
    // MARK: - Yardımcı Metotlar
    
    /// Mevcut kullanıcı kimliğini döndürür, yoksa hata fırlatır
    private func getCurrentUserId() throws -> String {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            throw AppError.authError
        }
        return userId
    }
    
    // MARK: - Grup İşlemleri
    
    /// Kullanıcının tüm şablon gruplarını getirir
    func fetchGroups() async throws -> [WorkoutTemplateGroup] {
        let userId = try getCurrentUserId()
        
        do {
            let snapshot = try await db.collection("templateGroups")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            return snapshot.documents.compactMap { document -> WorkoutTemplateGroup? in
                var group = try? document.data(as: WorkoutTemplateGroup.self)
                group?.id = document.documentID
                return group
            }
        } catch {
            throw AppError.databaseError("Gruplar yüklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Yeni bir şablon grubu oluşturur
    func createGroup(name: String) async throws -> String {
        let userId = try getCurrentUserId()
        
        guard !name.isEmpty else {
            throw AppError.validationError("Grup adı boş olamaz")
        }
        
        let data: [String: Any] = [
            "name": name,
            "userId": userId,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        do {
            let docRef = try await db.collection("templateGroups")
                .addDocument(data: data)
            return docRef.documentID
        } catch {
            throw AppError.databaseError("Grup oluşturulurken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Şablon grubunun adını günceller
    func updateGroupName(groupId: String, newName: String) async throws {
        try getCurrentUserId() // Kullanıcı oturumunu kontrol et
        
        guard !newName.isEmpty else {
            throw AppError.validationError("Grup adı boş olamaz")
        }
        
        do {
            try await db.collection("templateGroups")
                .document(groupId)
                .updateData([
                    "name": newName,
                    "updatedAt": Timestamp()
                ])
        } catch {
            throw AppError.databaseError("Grup adı güncellenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Bir şablon grubunu ve içindeki tüm şablonları siler
    func deleteGroup(groupId: String) async throws {
        try getCurrentUserId() // Kullanıcı oturumunu kontrol et
        
        do {
            // Önce gruptaki tüm şablonları sil
            let templatesSnapshot = try await db.collection("workoutTemplates")
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments()
            
            for document in templatesSnapshot.documents {
                try await db.collection("workoutTemplates")
                    .document(document.documentID)
                    .delete()
            }
            
            // Sonra grubu sil
            try await db.collection("templateGroups")
                .document(groupId)
                .delete()
        } catch {
            throw AppError.databaseError("Grup silinirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Şablon İşlemleri
    
    /// Belirli bir gruba ait veya tüm şablonları getirir
    func fetchTemplates(groupId: String? = nil) async throws -> [WorkoutTemplate] {
        let userId = try getCurrentUserId()
        
        do {
            var query: Query = db.collection("workoutTemplates")
                .whereField("userId", isEqualTo: userId)
            
            if let groupId = groupId {
                query = query.whereField("groupId", isEqualTo: groupId)
            }
            
            let snapshot = try await query.getDocuments()
            
            return snapshot.documents.compactMap { document -> WorkoutTemplate? in
                var template = try? document.data(as: WorkoutTemplate.self)
                template?.id = document.documentID
                return template
            }
        } catch {
            throw AppError.databaseError("Şablonlar yüklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Şablonları grup ID'lerine göre gruplandırılmış olarak getirir
    func fetchTemplatesByGroup() async throws -> [String: [WorkoutTemplate]] {
        let userId = try getCurrentUserId()
        
        do {
            let snapshot = try await db.collection("workoutTemplates")
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
            
            return templatesByGroup
        } catch {
            throw AppError.databaseError("Şablonlar yüklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Yeni bir şablon oluşturur
    func createTemplate(template: WorkoutTemplate) async throws -> String {
        let userId = try getCurrentUserId()
        
        guard !template.name.isEmpty else {
            throw AppError.validationError("Şablon adı boş olamaz")
        }
        
        guard !template.exercises.isEmpty else {
            throw AppError.validationError("Şablonda en az bir egzersiz olmalı")
        }
        
        guard template.groupId != nil && !template.groupId!.isEmpty else {
            throw AppError.validationError("Şablonun bir gruba ait olması gerekir")
        }
        
        var templateData = template
        templateData.userId = userId
        templateData.createdAt = Timestamp()
        templateData.updatedAt = Timestamp()
        
        do {
            let documentReference = try await db.collection("workoutTemplates").addDocument(data: templateData.toDictionary())
            return documentReference.documentID
        } catch {
            throw AppError.databaseError("Şablon kaydedilirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Var olan bir şablonu günceller
    func updateTemplate(template: WorkoutTemplate) async throws {
        guard let templateId = template.id, !templateId.isEmpty else {
            throw AppError.validationError("Geçersiz şablon ID'si")
        }
        
        guard !template.name.isEmpty else {
            throw AppError.validationError("Şablon adı boş olamaz")
        }
        
        guard !template.exercises.isEmpty else {
            throw AppError.validationError("Şablonda en az bir egzersiz olmalı")
        }
        
        var updatedTemplate = template
        updatedTemplate.updatedAt = Timestamp()
        
        do {
            try await db.collection("workoutTemplates")
                .document(templateId)
                .updateData(updatedTemplate.toDictionary())
        } catch {
            throw AppError.databaseError("Şablon güncellenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Bir şablonu siler
    func deleteTemplate(templateId: String) async throws {
        try getCurrentUserId() // Kullanıcı oturumunu kontrol et
        
        do {
            try await db.collection("workoutTemplates")
                .document(templateId)
                .delete()
        } catch {
            throw AppError.databaseError("Şablon silinirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    /// Şablondan bir egzersiz siler
    func deleteExerciseFromTemplate(templateId: String, exerciseId: String) async throws {
        try getCurrentUserId() // Kullanıcı oturumunu kontrol et
        
        // Önce şablonu getir
        do {
            let document = try await db.collection("workoutTemplates")
                .document(templateId)
                .getDocument()
            
            guard var template = try? document.data(as: WorkoutTemplate.self) else {
                throw AppError.notFoundError
            }
            
            // Egzersizi çıkar
            template.exercises.removeAll { $0.id == exerciseId }
            
            // Güncelle
            let exerciseData = template.exercises.map { exercise -> [String: Any] in
                [
                    "id": exercise.id,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.exerciseName,
                    "sets": exercise.sets,
                    "reps": exercise.reps,
                    "weight": exercise.weight as Any,
                    "notes": exercise.notes as Any
                ]
            }
            
            try await db.collection("workoutTemplates")
                .document(templateId)
                .updateData([
                    "exercises": exerciseData,
                    "updatedAt": Timestamp()
                ])
        } catch {
            throw AppError.databaseError("Egzersiz silinirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Performans İşlemleri
    
    /// Belirli bir egzersiz için önceki en iyi performansı getirir
    func fetchPreviousBest(exerciseId: String) async throws -> PreviousBest? {
        let userId = try getCurrentUserId()
        
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
            return nil
        } catch {
            throw AppError.databaseError("Performans verileri yüklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
} 
