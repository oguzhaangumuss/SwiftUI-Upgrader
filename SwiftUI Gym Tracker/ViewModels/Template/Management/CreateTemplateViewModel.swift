import SwiftUI
import FirebaseFirestore
import Combine

class CreateTemplateViewModel: BaseTemplateViewModel {
    // MARK: - Properties
    
    /// Şablona eklenecek egzersizler
    @Published var selectedExercises: [TemplateExercise] = []
    
    /// Şablon adı
    @Published var templateName: String = ""
    
    /// Egzersizler için önceki en iyi performanslar
    @Published var previousBests: [String: PreviousBest] = [:]
    
    /// Kullanılabilir şablon grupları
    @Published var groups: [WorkoutTemplateGroup] = []
    
    /// Seçili grup ID'si
    @Published var selectedGroupId: String = ""
    
    /// Grup seçiminin kilitli olup olmadığı
    @Published var isGroupSelectionLocked: Bool = false
    
    // MARK: - Initialization
    
    /// CreateTemplateViewModel başlatıcısı
    /// - Parameter groupId: Opsiyonel olarak başlangıçta seçilecek grup ID'si
    init(groupId: String? = nil) {
        super.init()
        
        if let groupId = groupId {
            self.selectedGroupId = groupId
            self.isGroupSelectionLocked = true
        }
        
        Task {
            await loadGroups()
        }
    }
    
    // MARK: - Group Management
    
    /// Mevcut grupları yükler
    @MainActor
    func loadGroups() async {
        startLoading()
        
        do {
            groups = try await repository.fetchGroups()
        } catch {
            handleError(error)
        }
        
        finishLoading()
    }
    
    // MARK: - Exercise Management
    
    /// Egzersizler için önceki en iyi performansları yükler
    @MainActor
    func loadPreviousBests() async {
        for exercise in selectedExercises where previousBests[exercise.exerciseId] == nil {
            do {
                if let best = try await repository.fetchPreviousBest(exerciseId: exercise.exerciseId) {
                    previousBests[exercise.exerciseId] = best
                }
            } catch {
                print("Geçmiş performans yüklenemedi: \(error.localizedDescription)")
            }
        }
    }
    
    /// Şablonu kaydetme işlemi
    @MainActor
    func saveTemplate() async {
        guard validate() else { return }
        
        startLoading()
        
        do {
            let template = createTemplateObject()
            let templateId = try await repository.createTemplate(template: template)
            
            NotificationCenter.default.post(name: .templateCreated, object: nil)
            print("✅ Şablon başarıyla oluşturuldu: \(templateId)")
            
            // Başarıyla kaydedildikten sonra alanları temizle
            resetForm()
        } catch {
            handleError(error)
        }
        
        finishLoading()
    }
    
    /// Bir egzersizi kaldırır
    func removeExercise(_ exercise: TemplateExercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
    }
    
    /// Bir egzersiz ekler
    func addExercise(_ exercise: Exercise) {
        let newExercise = TemplateExercise(
            id: UUID().uuidString,
            exerciseId: exercise.id ?? "",
            exerciseName: exercise.name,
            sets: 1,
            reps: 0,
            weight: 0
        )
        selectedExercises.append(newExercise)
    }
    
    // MARK: - Helpers
    
    /// Seçili grubun adını döndürür
    var selectedGroupName: String {
        groups.first(where: { $0.id == selectedGroupId })?.name ?? "Seçilmedi"
    }
    
    /// Şablon verisinin doğruluğunu kontrol eder
    private func validate() -> Bool {
        if templateName.isEmpty {
            errorMessage = "Lütfen şablon adı girin"
            return false
        }
        
        if selectedGroupId.isEmpty {
            errorMessage = "Lütfen bir grup seçin"
            return false
        }
        
        if selectedExercises.isEmpty {
            errorMessage = "En az bir egzersiz eklemelisiniz"
            return false
        }
        
        return true
    }
    
    /// WorkoutTemplate nesnesi oluşturur
    private func createTemplateObject() -> WorkoutTemplate {
        return WorkoutTemplate(
            id: nil,
            name: templateName,
            notes: nil,
            exercises: selectedExercises,
            createdBy: "",  // Repository tarafından doldurulacak userId
            userId: "",  // repository'de otomatik eklenecek
            createdAt: Timestamp(),  // Repository tarafından güncellenebilir
            updatedAt: Timestamp(),  // Repository tarafından güncellenebilir
            groupId: selectedGroupId
        )
    }
    
    /// Formu sıfırlar
    private func resetForm() {
        templateName = ""
        selectedExercises = []
        if !isGroupSelectionLocked {
            selectedGroupId = ""
        }
    }
} 
