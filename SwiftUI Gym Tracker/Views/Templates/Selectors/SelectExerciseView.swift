import SwiftUI

struct SelectExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExercisesViewModel()
    @State private var searchText = ""
    
    // İki farklı kullanım için gerekli property'ler
    var onExerciseSelected: ((Exercise) -> Void)?
    @Binding var selectedExercises: [TemplateExercise]
    
    // MARK: - Initializers
    init(onExerciseSelected: @escaping (Exercise) -> Void) {
        self.onExerciseSelected = onExerciseSelected
        self._selectedExercises = .constant([])
    }
    
    init(selectedExercises: Binding<[TemplateExercise]>) {
        self._selectedExercises = selectedExercises
        self.onExerciseSelected = nil
    }
    
    var body: some View {
        List {
            ForEach(filteredExercises) { exercise in
                ExerciseRowView(exercise: exercise)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleExerciseSelection(exercise)
                        dismiss()
                    }
            }
        }
        .searchable(text: $searchText, prompt: "Egzersiz Ara")
        .navigationTitle("Egzersiz Seç")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    dismiss()
                }
            }
        }
    }
    
    private func handleExerciseSelection(_ exercise: Exercise) {
        if let callback = onExerciseSelected {
            callback(exercise)
        } else {
            if let exerciseId = exercise.id,
               !selectedExercises.contains(where: { $0.exerciseId == exerciseId }) {
                let templateExercise = TemplateExercise(
                    id: UUID().uuidString,
                    exerciseId: exerciseId,
                    exerciseName: exercise.name,
                    sets: 1,
                    reps: 1,
                    weight: 1,
                    notes: nil
                )
                selectedExercises.append(templateExercise)
            }
        }
    }
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return viewModel.exercises
        }
        return viewModel.exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
} 
