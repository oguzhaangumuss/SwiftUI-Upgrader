import SwiftUI
import FirebaseFirestore

class RenameGroupViewModel: ObservableObject {
    // MARK: - Properties
    @Published var name: String
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let group: WorkoutTemplateGroup
    private let templateGroupsViewModel = TemplateGroupsViewModel()
    
    // MARK: - Init
    
    init(group: WorkoutTemplateGroup) {
        self.group = group
        self.name = group.name
    }
    
    // MARK: - Methods
    
    @MainActor
    func saveGroupName() async -> Bool {
        guard let groupId = group.id, !name.isEmpty else {
            errorMessage = "Grup adı boş olamaz"
            return false
        }
        
        if name == group.name {
            // İsim değişmemişse işlem yapmaya gerek yok
            return true
        }
        
        isLoading = true
        defer { isLoading = false }
        
        return await templateGroupsViewModel.renameGroup(groupId: groupId, newName: name)
    }
} 