import SwiftUI
import FirebaseFirestore

struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateTemplateViewModel()
    @State private var name = ""
    @State private var notes = ""
    @State private var selectedGroupId: String?
    @State private var showingExerciseSelector = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Şablon Bilgileri")) {
                    TextField("Şablon Adı", text: $name)
                    
                    TextEditor(text: $notes)
                        .frame(height: 50)
                        .placeholder(when: notes.isEmpty) {
                            Text("Not ekle")
                                .foregroundColor(.gray)
                        }
                    
                    if !viewModel.groups.isEmpty {
                        Picker("Grup", selection: $selectedGroupId) {
                            ForEach(viewModel.groups) { group in
                                Text(group.name)
                                    .tag(group.id as String?)
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        showingExerciseSelector = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Egzersiz Ekle")
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
                
                if !viewModel.selectedExercises.isEmpty {
                    Section(header: Text("Egzersizler")) {
                        ForEach(viewModel.selectedExercises.indices, id: \.self) { index in
                            ExerciseRow(
                                exercise: viewModel.selectedExercises[index],
                                previousBest: viewModel.previousBests[viewModel.selectedExercises[index].exerciseId],
                                onUpdate: { updatedExercise in
                                    viewModel.selectedExercises[index] = updatedExercise
                                }
                            )
                        }
                        .onDelete { indexSet in
                            viewModel.selectedExercises.remove(atOffsets: indexSet)
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Yeni Şablon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveTemplate()
                    }
                    .disabled(viewModel.isLoading || 
                             name.isEmpty || 
                             viewModel.selectedExercises.isEmpty || 
                             selectedGroupId == nil)
                }
            }
            .sheet(isPresented: $showingExerciseSelector) {
                ExerciseSelectorView(selectedExercises: $viewModel.selectedExercises)
            }
            .onChange(of: viewModel.selectedExercises) { exercises in
                Task {
                    await viewModel.fetchPreviousBests(for: exercises)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            if selectedGroupId == nil, let firstGroupId = viewModel.groups.first?.id {
                selectedGroupId = firstGroupId
            }
        }
    }
    
    private func saveTemplate() {
        Task {
            do {
                guard let groupId = selectedGroupId else {
                    errorMessage = "Lütfen bir grup seçin"
                    return
                }
                
                try await viewModel.saveTemplate(name: name, notes: notes, groupId: groupId)
                dismiss()
            } catch {
                errorMessage = "Şablon kaydedilemedi"
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateTemplateView()
    }
}

