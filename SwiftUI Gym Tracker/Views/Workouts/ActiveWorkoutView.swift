import SwiftUI
import FirebaseFirestore
import Foundation

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @State private var showingFinishAlert = false
    @State private var showingExerciseSelector = false
    
    init(template: WorkoutTemplate) {
        let viewModel = ActiveWorkoutViewModel()
        let activeExercises = template.exercises.map { $0.toActiveWorkoutExercise() }
        viewModel.setupExercises(activeExercises)
        viewModel.workoutName = template.name
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            workoutHeaderView
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach($viewModel.exercises) { $exercise in
                        ActiveExerciseSetupCard(
                            exercise: $exercise,
                            onDelete: {
                                withAnimation {
                                    viewModel.removeExercise(exercise)
                                }
                            }
                        )
                    }
                    
                    addExerciseButton
                }
                .padding(.vertical)
            }
            
            finishButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExerciseSelector) {
            NavigationView {
                ExerciseSelectorView { exercise in
                    let activeExercise = exercise.toActiveWorkoutExercise()
                    viewModel.exercises.append(activeExercise)
                }
            }
        }
        .alert("Antrenmanı Bitir", isPresented: $showingFinishAlert) {
            Button("Çıkış", role: .cancel) { 
                dismiss()
            }
            Button("Kaydet") {
                Task {
                    await viewModel.saveWorkout()
                    dismiss()
                }
            }
        }
    }
    
    private var workoutHeaderView: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Text(formatTime(viewModel.elapsedTime))
                    .font(.title)
                    .monospacedDigit()
                
                Button {
                    viewModel.resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                
            }
            
            TextField("Antrenman Adı", text: $viewModel.workoutName)
                .font(.title2)
                .multilineTextAlignment(.leading)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
    
    private var finishButton: some View {
        Button {
            showingFinishAlert = true
        } label: {
            HStack {
                Text("Antrenmanı Bitir")
                    .fontWeight(.semibold)
                Image(systemName: "checkmark.circle.fill")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private var addExerciseButton: some View {
        Button {
            showingExerciseSelector = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Egzersiz Ekle")
            }
            .foregroundColor(AppTheme.primaryColor)
            .padding()
        }
    }
    
    private func formatTime(_ duration: Double) -> String {
        let minutes = Int(duration / 60.0)
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


