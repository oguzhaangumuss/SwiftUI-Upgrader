import SwiftUI
import FirebaseFirestore

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @State private var showingAddToWorkoutSheet = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            exerciseInfoSection
            muscleGroupsSection
            detailsSection
        }
        .navigationTitle(exercise.name)
        .navigationBarItems(trailing: navigationButtons)
        .sheet(isPresented: $showingAddToWorkoutSheet) {
            AddToWorkoutView(exercise: exercise) {
                NotificationCenter.default.post(name: NSNotification.Name("RefreshWorkouts"), object: nil)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditExerciseView(exercise: exercise)
        }
        .alert("Egzersizi Sil", isPresented: $showingDeleteAlert) {
            Button("Sil", role: .destructive) {
                deleteExercise()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu egzersizi silmek istediğinizden emin misiniz?")
        }
    }
    
    // MARK: - View Components
    private var exerciseInfoSection: some View {
        Section(header: Text("Egzersiz Bilgileri")) {
            Text(exercise.description)
                .padding(.vertical, 4)
        }
    }
    
    private var muscleGroupsSection: some View {
        Section(header: Text("Kas Grupları")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercise.muscleGroups, id: \.self) { muscleGroup in
                        MuscleGroupCard(muscleGroup: muscleGroup)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets())
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Detaylar")) {
            HStack {
                Text("Oluşturulma")
                Spacer()
                Text(exercise.createdAt.dateValue().formatted())
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack {
            Button {
                showingAddToWorkoutSheet = true
            } label: {
                Image(systemName: "plus.circle")
            }
            
            if canEditExercise {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Düzenle", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private var canEditExercise: Bool {
        let currentUserId = FirebaseManager.shared.auth.currentUser?.uid
        return exercise.createdBy == currentUserId || FirebaseManager.shared.currentUser?.isAdmin == true
    }
    
    private func deleteExercise() {
        guard let exerciseId = exercise.id else { return }
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("exercises")
                    .document(exerciseId)
                    .delete()
                dismiss()
            } catch {
                print("Egzersiz silinemedi: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct MuscleGroupCard: View {
    let muscleGroup: MuscleGroup
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: muscleGroupIcon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            Text(muscleGroup.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var muscleGroupIcon: String {
        switch muscleGroup {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .legs: return "figure.run"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .cardio: return "heart.circle"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

// MARK: - Preview
struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseDetailView(exercise: Exercise.example)
        }
    }
} 
