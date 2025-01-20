import SwiftUI

struct ActiveExerciseSetupCard: View {
    @Binding var exercise: ActiveWorkoutExercise
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            ForEach($exercise.sets) { $set in
                SetRowView(set: $set, onRemove: {
                    var updatedExercise = exercise
                    updatedExercise.removeSet(at: set.setNumber)
                    exercise = updatedExercise
                })
            }
            
            addSetButton
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var headerView: some View {
        HStack {
            Text(exercise.exerciseName)
                .font(.headline)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var addSetButton: some View {
        Button {
            print("🔍 Set ekle butonuna tıklandı")
            print("🔍 Mevcut exercise durumu: \(exercise)")
            var updatedExercise = exercise
            updatedExercise.addSet()
            print("🔍 Set eklendi, exercise güncelleniyor")
            print("🔍 Güncellenmiş exercise: \(updatedExercise)")
            exercise = updatedExercise
            print("🔍 Exercise güncellendi")
        } label: {
            Label("Set Ekle", systemImage: "plus.circle")
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryColor)
        }
        .padding(.top, 4)
    }
}

struct SetRowView: View {
    @Binding var set: WorkoutSet
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Set silme butonu
            Button(action: onRemove) {
                Image(systemName: "minus")
                    .foregroundColor(.red)
                    .frame(width: 20)
            }
            
            // Set numarası
            SetNumberView(number: set.setNumber)
            
            // Geçmiş
            PreviousBestView(previousBest: set.previousBest)
            
            // Ağırlık
            WeightInputView(weight: $set.weight)
            
            // Tekrar
            RepsInputView(reps: $set.reps)
        }
    }
}

private struct SetNumberView: View {
    let number: Int
    
    var body: some View {
        VStack {
            Text("Set")
                .font(.caption)
            Text("\(number)")
                .font(.subheadline)
        }
        .frame(width: 40)
    }
}

private struct PreviousBestView: View {
    let previousBest: Double?
    
    var body: some View {
        VStack {
            Text("Geçmiş")
                .font(.caption)
            if let previousBest = previousBest {
                Text("\(Int(previousBest)) kg")
                    .font(.subheadline)
            } else {
                Text("-")
                    .font(.subheadline)
            }
        }
        .frame(width: 60)
    }
}

private struct WeightInputView: View {
    @Binding var weight: Double
    
    var body: some View {
        VStack {
            Text("Kg")
                .font(.caption)
            TextField("0", value: $weight, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .keyboardType(.decimalPad)
        }
    }
}

private struct RepsInputView: View {
    @Binding var reps: Int
    
    var body: some View {
        VStack {
            Text("Tekrar")
                .font(.caption)
            TextField("0", value: $reps, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .keyboardType(.numberPad)
        }
    }
} 

#Preview {
    ActiveExerciseSetupCard(exercise: .constant(ActiveWorkoutExercise(exerciseId: "1", exerciseName: "Bench Press")), onDelete: {})
}
