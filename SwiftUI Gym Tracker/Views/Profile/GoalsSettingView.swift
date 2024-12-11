import SwiftUI
import FirebaseFirestore

struct GoalsSettingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = GoalsViewModel()
    
    @State private var calorieGoal: String
    @State private var workoutGoal: String
    @State private var weightGoal: String
    @State private var showingError = false
    
    init() {
        let user = FirebaseManager.shared.currentUser
        _calorieGoal = State(initialValue: user?.calorieGoal.map(String.init) ?? "")
        _workoutGoal = State(initialValue: user?.workoutGoal.map(String.init) ?? "")
        _weightGoal = State(initialValue: user?.weightGoal.map { String(format: "%.1f", $0) } ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Günlük Hedefler")) {
                    TextField("Yakılacak Kalori (kcal)", text: $calorieGoal)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Haftalık Hedefler")) {
                    TextField("Antrenman Sayısı", text: $workoutGoal)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Uzun Vadeli Hedefler")) {
                    TextField("Hedef Kilo (kg)", text: $weightGoal)
                        .keyboardType(.decimalPad)
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Section {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Hedeflerim")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { saveGoals() }
                    .disabled(viewModel.isLoading)
            )
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func saveGoals() {
        Task {
            await viewModel.saveGoals(
                calorieGoal: Int(calorieGoal),
                workoutGoal: Int(workoutGoal),
                weightGoal: Double(weightGoal)
            )
            dismiss()
        }
    }
}

#Preview {
    GoalsSettingView()
} 
