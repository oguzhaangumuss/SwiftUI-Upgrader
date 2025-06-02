import SwiftUI
import FirebaseFirestore

struct StartWorkoutFromTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActiveWorkoutViewModel.shared
    
    let template: WorkoutTemplate
    
    @State private var workoutName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToActiveWorkout = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Antrenman Bilgileri")) {
                    TextField("Antrenman Adı", text: $workoutName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Şablon Bilgileri")) {
                    HStack {
                        Text("Şablon")
                        Spacer()
                        Text(template.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Egzersiz Sayısı")
                        Spacer()
                        Text("\(template.exercises.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Egzersizler")) {
                    ForEach(template.exercises) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            
                            HStack {
                                Text("\(exercise.sets) set")
                                Text("•")
                                Text("\(exercise.reps) tekrar")
                                if exercise.weight > 0 {
                                    Text("•")
                                    Text("\(String(format: "%.1f", exercise.weight)) kg")
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            if let notes = exercise.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Antrenmanı Başlat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: startWorkout) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Başlat")
                        }
                    }
                    .disabled(workoutName.isEmpty || isLoading)
                }
            }
            .onAppear {
                workoutName = template.name
            }
            .navigationDestination(isPresented: $navigateToActiveWorkout) {
                ActiveWorkoutView()
            }
        }
    }
    
    private func startWorkout() {
        guard !workoutName.isEmpty else {
            errorMessage = "Antrenman adı boş olamaz."
            return
        }
        
        isLoading = true
        
        // Set up the workout in the shared ActiveWorkoutViewModel
        let activeExercises = template.exercises.map { exercise in
            var sets: [WorkoutSet] = []
            for i in 1...exercise.sets {
                sets.append(WorkoutSet(setNumber: i, weight: exercise.weight, reps: exercise.reps))
            }
            
            // Create a new ActiveExercise with the required parameters
            var activeExercise = ActiveExercise(exerciseId: exercise.exerciseId, exerciseName: exercise.exerciseName)
            activeExercise.sets = sets
            activeExercise.notes = exercise.notes
            return activeExercise
        }
        
        viewModel.setupNewWorkout(
            name: workoutName,
            templateId: template.id,
            templateName: template.name,
            exercises: activeExercises
        )
        
        // Navigate to the active workout screen
        navigateToActiveWorkout = true
    }
}

#Preview {
    let timestamp = Timestamp()
    let templateExercise = TemplateExercise(
        id: "1",
        exerciseId: "ex1",
        exerciseName: "Bench Press",
        sets: 3,
        reps: 10,
        weight: 70.0,
        notes: "Focus on form"
    )
    
    let template = WorkoutTemplate(
        id: "template1",
        name: "Upper Body Workout",
        notes: "Monday workout",
        exercises: [templateExercise],
        createdBy: "user1",
        userId: "user1",
        createdAt: timestamp,
        updatedAt: timestamp,
        groupId: "group1"
    )
    
    return StartWorkoutFromTemplateView(template: template)
} 