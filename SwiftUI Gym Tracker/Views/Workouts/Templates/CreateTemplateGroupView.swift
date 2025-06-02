import SwiftUI
import FirebaseFirestore

struct CreateTemplateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TemplateGroupsViewModel()
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var onGroupCreated: (() -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grup Bilgileri")) {
                    TextField("Grup Adı", text: $name)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Yeni Grup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveGroup()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func saveGroup() {
        isLoading = true
        
        Task {
            do {
                try await viewModel.createGroup(name: name)
                
                await MainActor.run {
                    onGroupCreated?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Grup oluşturulamadı: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
} 