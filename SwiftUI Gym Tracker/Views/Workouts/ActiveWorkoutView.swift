import SwiftUI
import FirebaseFirestore

struct ActiveWorkoutView: View {
    let exercises: [TemplateExercise]
    @StateObject private var viewModel = ActiveWorkoutViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingFinishAlert = false
    
    private func finishWorkout() {
        Task {
            await viewModel.saveWorkout()
            dismiss()
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(exercises) { exercise in
                    ExerciseProgressSection(
                        exercise: exercise,
                        progress: viewModel.progress[exercise.id] ?? ExerciseProgress()
                    ) { progress in
                        viewModel.updateProgress(for: exercise.id, progress: progress)
                    }
                }
                
                Section {
                    Button {
                        showingFinishAlert = true
                    } label: {
                        Text("Antrenmanı Bitir")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Aktif Antrenman")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .alert("Antrenmanı Bitir", isPresented: $showingFinishAlert) {
                Button("İptal", role: .cancel) { }
                Button("Bitir") {
                    finishWorkout()
                }
            } message: {
                Text("Antrenmanı bitirmek istediğinizden emin misiniz?")
            }
            .onAppear {
                guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
                
                let template = WorkoutTemplate(
                    name: "Aktif Antrenman",
                    exercises: exercises,
                    createdBy: userId,
                    userId: userId,
                    createdAt: Timestamp(),
                    updatedAt: Timestamp()
                )
                viewModel.fetchWorkoutTemplates(for: template)
            }
        }
    }
    
    struct ExerciseProgressSection: View {
        let exercise: TemplateExercise
        let progress: ExerciseProgress
        let onProgressUpdate: (ExerciseProgress) -> Void
        
        var body: some View {
            Section(header: Text(exercise.exerciseName)) {
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
                    
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 8) {
                        ForEach(0..<exercise.sets, id: \.self) { setIndex in
                            let isCompleted = progress.completedSets.indices.contains(setIndex)
                            Button {
                                var updatedProgress = progress
                                if isCompleted {
                                    updatedProgress.completedSets.remove(at: setIndex)
                                } else {
                                    let set = ExerciseSet(
                                        reps: exercise.reps,
                                        weight: exercise.weight ?? 0,
                                        isCompleted: true
                                    )
                                    if setIndex >= updatedProgress.completedSets.count {
                                        updatedProgress.completedSets.append(set)
                                    } else {
                                        updatedProgress.completedSets.insert(set, at: setIndex)
                                    }
                                }
                                onProgressUpdate(updatedProgress)
                            } label: {
                                Circle()
                                    .fill(isCompleted ? AppTheme.primaryColor : Color(.systemGray5))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text("\(setIndex + 1)")
                                            .foregroundColor(isCompleted ? .white : .primary)
                                    )
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
