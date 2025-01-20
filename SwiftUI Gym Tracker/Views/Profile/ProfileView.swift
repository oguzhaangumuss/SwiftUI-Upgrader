import SwiftUI
import Charts

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var goalsViewModel = GoalsViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Profil Başlığı
                ProfileHeaderView(user: viewModel.user)
                    .padding(.horizontal)
                
                // 2. Kalori Özeti
                VStack(spacing: 8) {
                    Text("Günlük Kalori Özeti")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CalorieChartView(
                        consumed: viewModel.todaysStats.consumedCalories,
                        burned: viewModel.todaysStats.burnedCalories
                    )
                }
                .padding(.horizontal)
                
                // 3. Günlük İstatistikler
                VStack(spacing: 8) {
                    Text("Günlük İstatistikler")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    QuickStatsView(stats: viewModel.todaysStats)
                }
                .padding(.horizontal)
                
                // 4. Hedefler Özeti
                VStack(spacing: 8) {
                    HStack {
                        Text("Hedeflerim")
                            .font(.headline)
                        
                        Spacer()
                        
                        NavigationLink("Tümü") {
                            GoalsView()
                        }
                        .font(.subheadline)
                    }
                    
                    // Hedefler özet kartı
                    GoalsSummaryView(viewModel: goalsViewModel)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Profil")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .onAppear {
            Task {
                await viewModel.fetchUserData()
                await viewModel.fetchTodaysStats()
                await goalsViewModel.fetchWeeklyWorkoutData()
                goalsViewModel.fetchGoals()
            }
        }
        .refreshable {
            Task {
                await viewModel.fetchUserData()
                await viewModel.fetchTodaysStats()
            }
        }
    }
}

// Hedefler özet görünümü
struct GoalsSummaryView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.colorScheme) var colorScheme // Renk şemasını algılamak için
    
    var body: some View {
        VStack(spacing: 12) {
            // Antrenman Hedefi
            GoalProgressRow(
                title: "Haftalık Antrenman",
                current: Double(viewModel.workouts),
                target: viewModel.workoutGoal ?? 0
            )
            
            // Kalori Hedefi
            GoalProgressRow(
                title: "Yakılan Kalori",
                current: viewModel.caloriesBurned,
                target: viewModel.calorieGoal ?? 0
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground)) // Sistem grup arka plan rengi
        .cornerRadius(12)
    }
}

// Hedef ilerleme satırı
struct GoalProgressRow: View {
    let title: String
    let current: Double
    let target: Double
    
    var progress: Double {
        target > 0 ? min(current / target, 1.0) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
            
            HStack {
                Text("\(Int(current))/\(Int(target))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: progress)
                    .frame(width: 100)
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
} 
