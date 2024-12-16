import SwiftUI
import FirebaseFirestore

struct CreateTemplateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SelectTemplateGroupViewModel()
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
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        
        let groupData: [String: Any] = [
            "userId": userId,
            "name": name,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        Task {
            do {
                _ = try await FirebaseManager.shared.firestore
                    .collection("templateGroups")
                    .addDocument(data: groupData)
                
                await MainActor.run {
                    onGroupCreated?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Grup oluşturulamadı"
                    isLoading = false
                }
            }
        }
    }
} 