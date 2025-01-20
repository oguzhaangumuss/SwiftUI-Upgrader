import SwiftUI

struct CalorieBalanceView: View {
    @StateObject private var viewModel = CalorieBalanceViewModel()
    @State private var showingGoalSheet = false
    
    var body: some View {
        List {
            // Kalori Özeti
            Section {
                // Kalori Hedefi
                HStack {
                    VStack(alignment: .leading) {
                        Text("Günlük Hedef")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.calorieGoal ?? 0) kcal")
                            .font(.headline)
                    }
                    Spacer()
                    Button {
                        showingGoalSheet = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                    }
                }
                
                // Alınan Kaloriler
                HStack {
                    VStack(alignment: .leading) {
                        Text("Alınan Kalori")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.consumedCalories)) kcal")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(.orange)
                }
                
                // Yakılan Kaloriler
                HStack {
                    VStack(alignment: .leading) {
                        Text("Yakılan Kalori")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.burnedCalories)) kcal")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Image(systemName: "flame.circle.fill")
                        .foregroundColor(.green)
                }
                
                // Net Kalori
                HStack {
                    VStack(alignment: .leading) {
                        Text("Net Kalori")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.consumedCalories - viewModel.burnedCalories)) kcal")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Image(systemName: "equal.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Aktivite Dağılımı
            if !viewModel.activityDistribution.isEmpty {
                Section(header: Text("Aktivite Dağılımı")) {
                    ForEach(viewModel.activityDistribution) { activity in
                        HStack {
                            Text(activity.name)
                            Spacer()
                            Text("\(Int(activity.calories)) kcal")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let userId = FirebaseManager.shared.auth.currentUser?.uid {
                Task {
                    await viewModel.fetchCalorieData(userId: userId)
                }
            }
        }
        .sheet(isPresented: $showingGoalSheet) {
            CalorieGoalView(currentGoal: viewModel.calorieGoal ?? 0)
        }
        .refreshable {
            if let userId = FirebaseManager.shared.auth.currentUser?.uid {
                await viewModel.fetchCalorieData(userId: userId)
            }
        }
    }
} 
struct CalorieBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        CalorieBalanceView()
    }
}
#Preview {
    CalorieBalanceView()
}
