import SwiftUI
import Foundation

struct QuickStartWorkoutView: View {
    @StateObject private var viewModel = ActiveWorkoutViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingExerciseSelector = false
    @State private var showingFinishAlert = false
    @State private var showingSaveTemplateSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            workoutHeaderView
            
            if viewModel.exercises.isEmpty {
                emptyStateView
            } else {
                exerciseListView
            }
            
            finishButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Reset the view model state for a new quick start workout
            viewModel.setupNewWorkout(
                name: "Antrenman",
                templateId: nil,
                templateName: "",
                exercises: []
            )
        }
        .sheet(isPresented: $showingExerciseSelector) { exerciseSelectorSheet }
        .sheet(isPresented: $showingSaveTemplateSheet) { saveTemplateSheet }
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
    
    // MARK: - View Components
    private var workoutHeaderView: some View {
        HStack {
            Text(formatTime(viewModel.elapsedTime))
                .font(.title2)
                .monospacedDigit()
            
            TextField("Antrenman Adı", text: $viewModel.workoutName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Egzersiz ekleyerek başlayın")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                showingExerciseSelector = true
            } label: {
                Text("Egzersiz Ekle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppTheme.primaryColor)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var exerciseListView: some View {
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
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") { dismiss() }
            }
        }
    }
    
    private var exerciseSelectorSheet: some View {
        NavigationView {
            ExerciseSelectorView { exercise in
                let activeExercise = exercise.toActiveExercise()
                viewModel.exercises.append(activeExercise)
            }
        }
    }
    
    private var saveTemplateSheet: some View {
        NavigationView {
            SaveTemplateView(
                exercises: viewModel.exercises.map { $0.toTemplateExercise() },
                onSave: { name, groupId in
                    Task {
                        await saveAsTemplate(name: name, groupId: groupId)
                        dismiss()
                    }
                }
            )
        }
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
        .disabled(viewModel.exercises.isEmpty)
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ duration: Double) -> String {
        let hours = Int(duration / 3600.0)
        let minutes = Int(duration / 60.0) % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func saveAsTemplate(name: String, groupId: String) async {
        let templateExercises = viewModel.exercises.map { exercise -> TemplateExercise in
            return TemplateExercise(
                id: UUID().uuidString,
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                sets: exercise.sets.count,
                reps: exercise.sets.first?.reps ?? 0,
                weight: exercise.sets.first?.weight ?? 0,
                notes: exercise.notes
            )
        }
        
        // Template kaydetme işlemleri burada yapılacak
        // CreateTemplateViewModel'deki saveTemplate metodunu örnek alabilirsiniz
    }
}

#Preview {
    QuickStartWorkoutView()
}
