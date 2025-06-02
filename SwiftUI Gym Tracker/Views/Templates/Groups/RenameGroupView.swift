import SwiftUI
import FirebaseFirestore

struct RenameGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RenameGroupViewModel
    
    init(group: WorkoutTemplateGroup) {
        _viewModel = StateObject(wrappedValue: RenameGroupViewModel(group: group))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grup Bilgileri")) {
                    TextField("Grup Adı", text: $viewModel.name)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Grubu Yeniden Adlandır")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        Task {
                            if await viewModel.saveGroupName() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
} 