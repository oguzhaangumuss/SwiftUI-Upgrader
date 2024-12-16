import SwiftUI

struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditTemplateViewModel
    
    init(template: WorkoutTemplate) {
        _viewModel = StateObject(wrappedValue: EditTemplateViewModel(template: template))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Şablon Bilgileri")) {
                    TextField("Şablon Adı", text: $viewModel.name)
                    TextField("Notlar", text: $viewModel.notes)
                    
                    Picker("Grup", selection: $viewModel.selectedGroupId) {
                        ForEach(viewModel.availableGroups) { group in
                            Text(group.name)
                                .tag(group.id)
                        }
                    }
                }
                
                Section(header: Text("Egzersizler")) {
                    ForEach($viewModel.exercises) { $exercise in
                        TemplateExerciseRowView(exercise: $exercise)
                    }
                    .onMove { from, to in
                        viewModel.exercises.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { indexSet in
                        viewModel.exercises.remove(atOffsets: indexSet)
                    }
                    
                    NavigationLink("Egzersiz Ekle") {
                        SelectExerciseView(selectedExercises: $viewModel.exercises)
                    }
                }
            }
            .navigationTitle("Şablonu Düzenle")
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
                            await viewModel.saveTemplate()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

// Egzersiz satırı görünümü
struct TemplateExerciseRowView: View {
    @Binding var exercise: TemplateExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Set")
                        .font(.caption)
                    TextField("Set", value: $exercise.sets, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading) {
                    Text("Tekrar")
                        .font(.caption)
                    TextField("Tekrar", value: $exercise.reps, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading) {
                    Text("Ağırlık (kg)")
                        .font(.caption)
                    TextField("Ağırlık", value: $exercise.weight, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .keyboardType(.decimalPad)
                }
            }
            
            TextField("Not ekle", text: Binding(
                get: { exercise.notes ?? "" },
                set: { exercise.notes = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
} 
