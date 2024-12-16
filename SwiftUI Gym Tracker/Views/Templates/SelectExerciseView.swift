import SwiftUI

struct SelectExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExercisesViewModel()
    @Binding var selectedExercises: [TemplateExercise]
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredExercises) { exercise in
                    ExerciseRowView(exercise: exercise)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let exerciseId = exercise.id,
                               !selectedExercises.contains(where: { $0.exerciseId == exerciseId }) {
                                let templateExercise = TemplateExercise(
                                    id: UUID().uuidString,
                                    exerciseId: exerciseId,
                                    exerciseName: exercise.name,
                                    sets: 3,
                                    reps: 10,
                                    weight: nil,
                                    notes: nil
                                )
                                selectedExercises.append(templateExercise)
                            }
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
    }
    
    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return viewModel.exercises
        }
        return viewModel.exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
} 