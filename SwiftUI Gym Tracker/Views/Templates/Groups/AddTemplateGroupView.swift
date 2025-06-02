import SwiftUI

struct AddTemplateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var onSave: (String) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Grup Bilgileri")) {
                    TextField("Grup Adı", text: $groupName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
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
                    Button(action: saveGroup) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Kaydet")
                        }
                    }
                    .disabled(groupName.isEmpty || isLoading)
                }
            }
        }
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private func saveGroup() {
        guard !groupName.isEmpty else {
            errorMessage = "Grup adı boş olamaz."
            return
        }
        
        isLoading = true
        
        // Call the completion handler with the group name
        onSave(groupName)
        
        // Dismiss the view
        dismiss()
    }
}

#Preview {
    AddTemplateGroupView(onSave: { _ in })
} 