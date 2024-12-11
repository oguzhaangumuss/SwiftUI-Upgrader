import SwiftUI
struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else {
                // Kalori Hedefi
                GoalSection(
                    title: "Kalori Hedefi",
                    current: viewModel.currentCalories,
                    target: viewModel.calorieGoal,
                    onEdit: { viewModel.editCalorieGoal() }
                )
                
                // Antrenman Hedefi
                GoalSection(
                    title: "Haftalık Antrenman",
                    current: viewModel.currentWorkouts,
                    target: viewModel.workoutGoal,
                    onEdit: { viewModel.editWorkoutGoal() }
                )
                
                // Kilo Hedefi
                GoalSection(
                    title: "Kilo Hedefi",
                    current: viewModel.currentWeight,
                    target: viewModel.weightGoal,
                    onEdit: { viewModel.editWeightGoal() }
                )
                
                // İlerleme Özeti
                ProgressSummaryView(progress: viewModel.progress)
            }
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Hedeflerim")
        .refreshable {
            viewModel.fetchGoals()
        }
    }
} 
