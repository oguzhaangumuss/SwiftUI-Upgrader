import SwiftUI
import FirebaseFirestore

struct AddToWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    var onWorkoutAdded: (() -> Void)?
    
    @State private var selectedDate = Date()
    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var notes = ""
    @State private var errorMessage = ""
    @State private var hours = ""
    @State private var minutes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Antrenman Detayları")) {
                    DatePicker("Tarih", selection: $selectedDate, displayedComponents: .date)
                    
                    TextField("Set Sayısı", text: $sets)
                        .keyboardType(.numberPad)
                    
                    TextField("Tekrar Sayısı", text: $reps)
                        .keyboardType(.numberPad)
                    
                    TextField("Ağırlık (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .placeholder(when: notes.isEmpty) {
                            Text("Notlar (Opsiyonel)")
                                .foregroundColor(.gray)
                        }
                }
                
                Section(header: Text("Süre")) {
                    HStack {
                        TextField("0", text: $hours)
                            .keyboardType(.numberPad)
                        Text("saat")
                        
                        TextField("0", text: $minutes)
                            .keyboardType(.numberPad)
                        Text("dakika")
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Antrenmana Ekle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Ekle") { addToWorkout() }
            )
        }
    }
    
    private func addToWorkout() {
        // Validasyon
        guard !sets.isEmpty, let setsInt = Int(sets) else {
            errorMessage = "Geçerli bir set sayısı girin"
            return
        }
        
        guard !reps.isEmpty, let repsInt = Int(reps) else {
            errorMessage = "Geçerli bir tekrar sayısı girin"
            return
        }
        
        guard !weight.isEmpty, let weightDouble = Double(weight) else {
            errorMessage = "Geçerli bir ağırlık girin"
            return
        }
        
        guard let exerciseId = exercise.id else {
            errorMessage = "Egzersiz ID'si bulunamadı"
            return
        }
        
        guard let hoursInt = Int(hours), let minutesInt = Int(minutes) else {
            errorMessage = "Geçerli bir süre girin"
            return
        }
        
        let duration = TimeInterval(hoursInt * 3600 + minutesInt * 60)
        
        // Kalori hesaplama
        let caloriesBurned = exercise.calculateCalories(
            weight: FirebaseManager.shared.currentUser?.weight ?? 70,
            duration: duration
        )
        
        // Yeni antrenman egzersizi oluştur
        let workoutExercise: [String: Any] = [
            "exerciseId": exerciseId,
            "exerciseName": exercise.name,
            "sets": setsInt,
            "reps": repsInt,
            "weight": weightDouble,
            "notes": notes,
            "date": Timestamp(date: selectedDate),
            "userId": FirebaseManager.shared.auth.currentUser?.uid ?? "",
            "duration": duration,
            "caloriesBurned": caloriesBurned,
            "createdAt": Timestamp()
        ]
        
        print("Kaydedilecek antrenman: \(workoutExercise)")
        
        // Firestore'a kaydet
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("userExercises")
                    .document()
                    .setData(workoutExercise)
                
                await MainActor.run {
                    onWorkoutAdded?()
                    dismiss()
                }
            } catch {
                errorMessage = "Antrenman eklenemedi: \(error.localizedDescription)"
            }
        }
    }
}

// TextEditor için placeholder eklentisi
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 