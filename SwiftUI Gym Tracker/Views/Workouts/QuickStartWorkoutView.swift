import SwiftUI
import FirebaseFirestore

struct QuickStartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuickStartWorkoutViewModel()
    @State private var showingExerciseSelector = false
    @State private var workoutNotes = ""
    
    var body: some View {
        NavigationView {
            Form {
                exercisesSection
                notesSection
                errorSection
            }
            .navigationTitle("Hızlı Başlangıç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingExerciseSelector) {
                ExerciseSelectorView(selectedExercises: $viewModel.selectedExercises)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private var exercisesSection: some View {
        Section(header: Text("Seçilen Egzersizler")) {
            if viewModel.selectedExercises.isEmpty {
                Text("Henüz egzersiz seçilmedi")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.selectedExercises) { exercise in
                    ExerciseConfigurationRow(
                        exercise: exercise,
                        onDelete: { viewModel.removeExercise(exercise) }
                    )
                }
            }
            
            Button {
                showingExerciseSelector = true
            } label: {
                Label("Egzersiz Ekle", systemImage: "plus.circle")
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Antrenman Notları")) {
            TextEditor(text: $workoutNotes)
                .frame(height: 100)
        }
    }
    
    private var errorSection: some View {
        Group {
            if !viewModel.errorMessage.isEmpty {
                Section {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Başla") {
                    startWorkout()
                }
                .disabled(viewModel.selectedExercises.isEmpty || viewModel.isLoading)
            }
        }
    }
    
    //MARK: burası düzenlenecek.
    private func startWorkout() {
        Task {
            await viewModel.startWorkout(notes: workoutNotes)
            dismiss()
        }
    }
}

// MARK: - Supporting Views
struct ExerciseConfigurationRow: View {
    let exercise: TemplateExercise
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            exerciseDetails
        }
        .padding(.vertical, 4)
    }
    
    private var exerciseDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(exercise.sets) set", systemImage: "number.square")
                Spacer()
                Label("\(exercise.reps) tekrar", systemImage: "repeat")
                if let weight = exercise.weight {
                    Spacer()
                    Label("\(Int(weight)) kg", systemImage: "scalemass")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if let notes = exercise.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
} 

#Preview {
    QuickStartWorkoutView()
}
