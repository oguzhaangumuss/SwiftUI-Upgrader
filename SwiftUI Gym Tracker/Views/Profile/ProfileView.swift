import SwiftUI
import Charts

// Zaman aralığı için enum
enum TimeInterval: String, CaseIterable, Identifiable {
    case daily = "Günlük"
    case weekly = "Haftalık"
    case monthly = "Aylık"
    
    var id: String { self.rawValue }
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var goalsViewModel = GoalsViewModel()
    @State private var showingSettings = false
    
    // Zaman aralığı seçimleri
    @State private var calorieTimeInterval: TimeInterval = .daily
    @State private var statsTimeInterval: TimeInterval = .daily
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Profil Başlığı
                ProfileHeaderView(user: viewModel.user)
                    .padding(.horizontal)
                
                // 2. Kalori Özeti
                VStack(spacing: 8) {
                    HStack {
                        Text(timeIntervalTitle(for: calorieTimeInterval, base: "Kalori Özeti"))
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("", selection: $calorieTimeInterval) {
                            ForEach(TimeInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    CalorieChartView(
                        consumed: viewModel.getConsumedCalories(for: calorieTimeInterval),
                        burned: viewModel.getBurnedCalories(for: calorieTimeInterval)
                    )
                }
                .padding(.horizontal)
                .onChange(of: calorieTimeInterval) { _ in
                    Task {
                        await viewModel.fetchStatsForTimeInterval(calorieTimeInterval)
                    }
                }
                
                // 3. Günlük İstatistikler
                VStack(spacing: 8) {
                    HStack {
                        Text(timeIntervalTitle(for: statsTimeInterval, base: "İstatistikler"))
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("", selection: $statsTimeInterval) {
                            ForEach(TimeInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    QuickStatsView(stats: viewModel.getStats(for: statsTimeInterval))
                }
                .padding(.horizontal)
                .onChange(of: statsTimeInterval) { _ in
                    Task {
                        await viewModel.fetchStatsForTimeInterval(statsTimeInterval)
                    }
                }
                
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
                await viewModel.fetchStatsForTimeInterval(.daily)
                await goalsViewModel.fetchWeeklyWorkoutData()
                goalsViewModel.fetchGoals()
            }
        }
        .refreshable {
            Task {
                await viewModel.fetchUserData()
                await viewModel.fetchStatsForTimeInterval(calorieTimeInterval)
                await viewModel.fetchStatsForTimeInterval(statsTimeInterval)
            }
        }
    }
    
    // Zaman aralığı başlığı için yardımcı fonksiyon
    private func timeIntervalTitle(for interval: TimeInterval, base: String) -> String {
        switch interval {
        case .daily: return "Günlük \(base)"
        case .weekly: return "Haftalık \(base)"
        case .monthly: return "Aylık \(base)"
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
            
            // Kilo Hedefi
            if let weightGoal = viewModel.weightGoal {
                WeightGoalRow(
                    current: viewModel.weight,
                    target: weightGoal
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground)) // Sistem grup arka plan rengi
        .cornerRadius(12)
    }
}

// Özel kilo hedefi satırı
struct WeightGoalRow: View {
    let current: Double
    let target: Double
    
    private var isWeightLoss: Bool {
        target < current
    }
    
    private var isWeightGain: Bool {
        target > current
    }
    
    private var progress: Double {
        if isWeightLoss {
            let initialWeight = FirebaseManager.shared.currentUser?.initialWeight ?? current
            return min(max((initialWeight - current) / (initialWeight - target), 0), 1.0)
        } else if isWeightGain {
            let initialWeight = FirebaseManager.shared.currentUser?.initialWeight ?? current
            return min(max((current - initialWeight) / (target - initialWeight), 0), 1.0)
        } else {
            return 1.0
        }
    }
    
    var title: String {
        if isWeightLoss {
            return "Kilo Verme"
        } else if isWeightGain {
            return "Kilo Alma"
        } else {
            return "Kilo Hedefi"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
            
            HStack {
                Text("\(String(format: "%.1f", current))/\(String(format: "%.1f", target)) kg")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: progress)
                    .frame(width: 100)
            }
        }
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
