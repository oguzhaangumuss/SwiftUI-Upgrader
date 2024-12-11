import SwiftUI

struct CalorieGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var goalCalories: Int
    
    init(currentGoal: Int) {
        _goalCalories = State(initialValue: currentGoal)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Günlük Kalori Hedefi")) {
                    TextField("Kalori", value: $goalCalories, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Kalori Hedefi")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { saveGoal() }
            )
        }
    }
    
    private func saveGoal() {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("users")
                    .document(userId)
                    .updateData(["calorieGoal": goalCalories])
                
                dismiss()
            } catch {
                print("Hedef kaydedilemedi: \(error)")
            }
        }
    }
} 
//struct CalorieGoalView_Previews: PreviewProvider {
//    static var previews: some View {
//        CalorieGoalView()
//    }
//}
