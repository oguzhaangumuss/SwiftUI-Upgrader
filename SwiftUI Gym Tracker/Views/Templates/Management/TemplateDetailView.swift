import SwiftUI
import FirebaseFirestore

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TemplateDetailViewModel
    @State private var showingStartWorkoutSheet = false
    @State private var showingDeleteAlert = false
    
    let template: WorkoutTemplate
    
    init(template: WorkoutTemplate) {
        self.template = template
        _viewModel = StateObject(wrappedValue: TemplateDetailViewModel(template: template))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Template header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let notes = template.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("\(template.exercises.count) egzersiz", systemImage: "dumbbell.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    
                    // Exercises
                    Text("Egzersizler")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        ForEach(template.exercises) { exercise in
                            exerciseCard(exercise: exercise)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingStartWorkoutSheet = true
                        }) {
                            Label("Antrenmanı Başlat", systemImage: "play.fill")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Şablonu Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Şablonu Sil", isPresented: $showingDeleteAlert) {
                Button("Sil", role: .destructive) {
                    Task {
                        await viewModel.deleteTemplate()
                        dismiss()
                    }
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("'\(template.name)' şablonunu silmek istediğinize emin misiniz?")
            }
            .sheet(isPresented: $showingStartWorkoutSheet) {
                StartWorkoutFromTemplateView(template: template)
            }
        }
    }
    
    private func exerciseCard(exercise: TemplateExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.exerciseName)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Label("\(exercise.sets) set", systemImage: "repeat")
                    .font(.subheadline)
                
                Label("\(exercise.reps) tekrar", systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline)
                
                if exercise.weight > 0 {
                    Label("\(String(format: "%.1f", exercise.weight)) kg", systemImage: "scalemass.fill")
                        .font(.subheadline)
                }
            }
            .foregroundColor(.secondary)
            
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let timestamp = Timestamp()
    let exercise = TemplateExercise(
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
        exercises: [exercise],
        createdBy: "user1",
        userId: "user1",
        createdAt: timestamp,
        updatedAt: timestamp,
        groupId: "group1"
    )
    
    return TemplateDetailView(template: template)
}
