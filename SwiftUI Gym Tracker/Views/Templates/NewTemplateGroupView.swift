import SwiftUI
import FirebaseFirestore

struct NewTemplateGroupView: View {
    let onGroupCreated: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TemplateGroupsViewModel()
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(onGroupCreated: @escaping (String) -> Void) {
        self.onGroupCreated = onGroupCreated
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grup Bilgileri")) {
                    TextField("Grup Adı", text: $groupName)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Yeni Grup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func createGroup() {
        isLoading = true
        
        Task {
            do {
                let groupId = try await viewModel.createGroup(name: groupName)
                await MainActor.run {
                    onGroupCreated(groupId)
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
} 
#Preview {
    NewTemplateGroupView(onGroupCreated: { _ in })
}
