import SwiftUI

struct SaveTemplateView: View {
    let exercises: [TemplateExercise]
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TemplateGroupsViewModel()
    @State private var templateName = ""
    @State private var selectedGroupId = ""
    @State private var showingNewGroupSheet = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            // Template Section
            Section {
                TextField("Şablon Adı", text: $templateName)
                
                if !viewModel.groups.isEmpty {
                    Picker("Grup Seçin", selection: $selectedGroupId) {
                        Text("Grup Seçin").tag("")
                        ForEach(viewModel.groups) { group in
                            Text(group.name).tag(group.id ?? "")
                        }
                    }
                }
                
                Button("Yeni Grup Oluştur") {
                    showingNewGroupSheet = true
                }
            } header: {
                Text("Şablon Bilgileri")
            }
            
            // Error Section
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Şablon Olarak Kaydet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") { dismiss() }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
                    guard !templateName.isEmpty, !selectedGroupId.isEmpty else {
                        errorMessage = "Lütfen şablon adı ve grup seçin"
                        return
                    }
                    onSave(templateName, selectedGroupId)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingNewGroupSheet) {
            NewTemplateGroupView { groupId in
                selectedGroupId = groupId
            }
        }
        .task {
            await viewModel.fetchGroups()
        }
    }
} 
#Preview {
    SaveTemplateView(exercises: [], onSave: { _, _ in })
}
