import SwiftUI
import FirebaseFirestore

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AdminExercisesViewModel()
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedMuscleGroups: Set<MuscleGroup> = []
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Egzersiz Bilgileri")) {
                    TextField("İsim", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section(header: Text("Kas Grupları")) {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        Toggle(group.rawValue, isOn: Binding(
                            get: { selectedMuscleGroups.contains(group) },
                            set: { isSelected in
                                if isSelected {
                                    selectedMuscleGroups.insert(group)
                                } else {
                                    selectedMuscleGroups.remove(group)
                                }
                            }
                        ))
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Yeni Egzersiz")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { saveExercise() }
            )
        }
    }
    
    private func saveExercise() {
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
        
        // Önce document referansı oluşturalım
        let docRef = FirebaseManager.shared.firestore.collection("exercises").document()
        
        // Yeni egzersiz verisi oluştur
        let exerciseData: [String: Any] = [
            "name": name,
            "description": description,
            "muscleGroups": Array(selectedMuscleGroups).map { $0.rawValue },
            "createdBy": FirebaseManager.shared.auth.currentUser?.uid ?? "",
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "averageRating": 0.0,
            "totalRatings": 0
        ]
        
        // Firestore'a kaydet
        Task {
            do {
                try await docRef.setData(exerciseData)
                dismiss()
            } catch {
                errorMessage = "Egzersiz kaydedilemedi: \(error.localizedDescription)"
            }
        }
    }
} 
