import SwiftUI

struct ExerciseSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExercisesViewModel()
    @Binding var selectedExercises: [TemplateExercise]
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    
    private var filteredExercises: [Exercise] {
        viewModel.exercises
            .filter { exercise in
                // Kas grubu filtresi
                if let group = selectedMuscleGroup {
                    guard exercise.muscleGroups.contains(group) else { return false }
                }
                // Arama filtresi
                if !searchText.isEmpty {
                    return exercise.name.localizedCaseInsensitiveContains(searchText)
                }
                return true
            }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Arama çubuğu
                SearchBar(text: $searchText, placeholder: "Egzersiz Ara...")
                    .padding()
                
                // Kas grubu seçici
                MuscleGroupSelector(selectedGroup: $selectedMuscleGroup)
                
                // Egzersiz listesi
                List {
                    ForEach(filteredExercises) { exercise in
                        ExerciseRowView(exercise: exercise)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectExercise(exercise)
                            }
                    }
                }
            }
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
    
    private func selectExercise(_ exercise: Exercise) {
        guard let exerciseId = exercise.id,
              !selectedExercises.contains(where: { $0.exerciseId == exerciseId }) else { return }
        
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
        dismiss()
    }
}
