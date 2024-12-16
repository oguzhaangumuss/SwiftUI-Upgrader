import SwiftUI
import FirebaseFirestore

struct NewTemplateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isLoading = true
        
        let data: [String: Any] = [
            "name": groupName,
            "userId": userId,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp()
        ]
        
        Task {
            do {
                _ = try await FirebaseManager.shared.firestore
                    .collection("templateGroups")
                    .addDocument(data: data)
                
                await MainActor.run {
                    NotificationCenter.default.post(name: .groupCreated, object: nil)
                    dismiss()
                }
            } catch {
                errorMessage = "Grup oluşturulamadı: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
} 