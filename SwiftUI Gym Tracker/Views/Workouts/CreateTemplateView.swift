import SwiftUI
import FirebaseFirestore

struct CreateTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: CreateTemplateViewModel
    @State private var showingExerciseSheet = false
    @State private var showingAlert = false
    @State private var templateName = ""
    
    init(selectedGroupId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CreateTemplateViewModel(groupId: selectedGroupId))
    }
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                templateNameField
                
                if !viewModel.isGroupSelectionLocked {
                    GroupSelectorButton(viewModel: viewModel)
                }
                
                exerciseList
                
                addExerciseButton
            }
            .padding(.vertical)
        }
        .navigationTitle("Şablon Oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            navigationBarButtons
        }
        .sheet(isPresented: $showingExerciseSheet) {
            NavigationView {
                SelectExerciseView(selectedExercises: $viewModel.selectedExercises)
            }
        }
        .alert("Hata", isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text("Şablon kaydedilirken bir hata oluştu.")
        }
    }
    
    private var templateNameField: some View {
        TextField("Şablon Adı", text: $templateName)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
    }
    
    private var exerciseList: some View {
        ForEach($viewModel.selectedExercises) { $exercise in
            TemplateExerciseSetupCard(
                exercise: $exercise,
                onDelete: {
                    viewModel.removeExercise(exercise)
                }
            )
        }
    }
    
    private func binding(for exercise: TemplateExercise) -> Binding<TemplateExercise> {
        Binding(
            get: { exercise },
            set: { newValue in
                if let index = viewModel.selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                    viewModel.selectedExercises[index] = newValue
                }
            }
        )
    }
    
    private var addExerciseButton: some View {
        Button {
            showingExerciseSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Egzersiz Ekle")
            }
            .foregroundColor(AppTheme.primaryColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
        }
    }
    
    private var navigationBarButtons: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
                    saveTemplate()
                }
                .disabled(templateName.isEmpty || viewModel.selectedExercises.isEmpty)
            }
        }
    }
    
    private func saveTemplate() {
        Task {
            do {
                try await viewModel.saveTemplate(name: templateName)
                dismiss()
            } catch {
                showingAlert = true
            }
        }
    }
}

private struct GroupSelectorButton: View {
    @ObservedObject var viewModel: CreateTemplateViewModel
    @State private var showingGroupSelector = false
    
    var body: some View {
        Button {
            showingGroupSelector = true
        } label: {
            HStack {
                Text("Grup Seç")
                Spacer()
                Text(viewModel.selectedGroupName)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingGroupSelector) {
            SelectTemplateGroupView { group in
                viewModel.selectedGroupId = group.id ?? ""
            }
        }
    }
}

#Preview {
    CreateTemplateView()
}

