import SwiftUI

struct TemplateDetailView: View {
    let template: WorkoutTemplate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showingStartWorkoutAlert = false
    @State private var showingActiveWorkout = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Egzersizler")) {
                    ForEach(template.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            
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
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingStartWorkoutAlert = true
                    } label: {
                        Text("Başla")
                            .bold()
                    }
                }
            }
            .alert("Antrenman'a Başla", isPresented: $showingStartWorkoutAlert) {
                Button("İptal", role: .cancel) { }
                Button("Başla") {
                    startWorkout()
                }
            } message: {
                Text("Bu şablon ile yeni bir antrenman başlatmak istiyor musunuz?")
            }
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView(exercises: template.exercises)
            }
        }
    }
    
    private func startWorkout() {
        showingActiveWorkout = true
    }
} 