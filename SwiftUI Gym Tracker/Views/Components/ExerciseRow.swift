import SwiftUI

public struct ExerciseRow: View {
    let exercise: TemplateExercise
    let previousBest: PreviousBest?
    let onUpdate: (TemplateExercise) -> Void
    @State private var showingConfigSheet = false
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            if let best = previousBest {
                Text("Geçmiş en iyi: \(Int(best.weight))kg x \(best.reps) tekrar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(exercise.sets) set", systemImage: "number.square")
                Spacer()
                Label("\(exercise.reps) tekrar", systemImage: "repeat")
                    Spacer()
                Label("\(Int(exercise.weight)) kg", systemImage: "scalemass")
                
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            showingConfigSheet = true
        }
        .sheet(isPresented: $showingConfigSheet) {
            ExerciseConfigSheet(exercise: exercise) { updatedExercise in
                onUpdate(updatedExercise)
            }
        }
    }
}

private struct ExerciseConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: TemplateExercise
    let onSave: (TemplateExercise) -> Void
    
    @State private var sets: Int
    @State private var reps: Int
    @State private var weight: Double?
    
    init(exercise: TemplateExercise, onSave: @escaping (TemplateExercise) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        _sets = State(initialValue: exercise.sets)
        _reps = State(initialValue: exercise.reps)
        _weight = State(initialValue: exercise.weight)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        VStack {
                            Text("Set")
                            TextField("0", value: $sets, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        Spacer()
                        VStack {
                            Text("Kg")
                            TextField("0", value: Binding(
                                get: { weight ?? 0 },
                                set: { weight = $0 }
                            ), format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        Spacer()
                        VStack {
                            Text("Tekrar")
                            TextField("0", value: $reps, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
            }
            .navigationTitle(exercise.exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        var updatedExercise = exercise
                        updatedExercise.sets = sets
                        updatedExercise.reps = reps
                        updatedExercise.weight = weight!
                        onSave(updatedExercise)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseRow(
        exercise: TemplateExercise(
            id: "1",
            exerciseId: "1",
            exerciseName: "Bench Press",
            sets: 3,
            reps: 10,
            weight: 60,
            notes: nil
        ),
        previousBest: PreviousBest(
            weight: 70,
            reps: 8,
            date: Date()
        ),
        onUpdate: { _ in }
    )
} 
