import SwiftUI
import FirebaseFirestore

struct EditExerciseView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    
    @State private var name: String
    @State private var description: String
    @State private var selectedMuscleGroups: Set<MuscleGroup>
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _name = State(initialValue: exercise.name)
        _description = State(initialValue: exercise.description)
        _selectedMuscleGroups = State(initialValue: Set(exercise.muscleGroups))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Egzersiz Bilgileri")) {
                    TextField("İsim", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section(header: Text("Kas Grupları")) {
                    ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                        Toggle(muscleGroup.rawValue, isOn: Binding(
                            get: { selectedMuscleGroups.contains(muscleGroup) },
                            set: { isSelected in
                                if isSelected {
                                    selectedMuscleGroups.insert(muscleGroup)
                                } else {
                                    selectedMuscleGroups.remove(muscleGroup)
                                }
                            }
                        ))
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Egzersizi Düzenle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { updateExercise() }
                    .disabled(isLoading)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func updateExercise() {
        // Validasyon
        guard !name.isEmpty else {
            errorMessage = "Egzersiz adı boş olamaz"
            return
        }
        
        guard !description.isEmpty else {
            errorMessage = "Egzersiz açıklaması boş olamaz"
            return
        }
        
        guard !selectedMuscleGroups.isEmpty else {
            errorMessage = "En az bir kas grubu seçmelisiniz"
            return
        }
        
        // ID kontrolü
        guard let exerciseId = exercise.id else {
            errorMessage = "Egzersiz ID'si bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let exerciseData: [String: Any] = [
            "name": name,
            "description": description,
            "muscleGroups": Array(selectedMuscleGroups).map { $0.rawValue },
            "updatedAt": Timestamp()
        ]
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("exercises")
                    .document(exerciseId)
                    .updateData(exerciseData)
                dismiss()
            } catch {
                errorMessage = "Egzersiz güncellenirken hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
} 