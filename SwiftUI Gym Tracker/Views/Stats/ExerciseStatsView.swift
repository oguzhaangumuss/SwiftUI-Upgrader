import SwiftUI
import Charts

struct ExerciseStatsView: View {
    @StateObject private var viewModel = ExerciseStatsViewModel()
    @State private var selectedPeriod: StatsPeriod = .weekly
    
    enum StatsPeriod: String, CaseIterable {
        case weekly = "Haftalık"
        case monthly = "Aylık"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Periyot seçici
                Picker("Periyot", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Toplam değerler
                TotalExerciseStats(stats: viewModel.currentStats)
                
                // Kalori grafiği
                CaloriesBurnedChart(data: viewModel.chartData)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                
                // Egzersiz dağılımı
                ExerciseDistributionChart(data: viewModel.exerciseDistribution)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Egzersiz İstatistikleri")
        .onChange(of: selectedPeriod) { newPeriod in
            Task {
                await viewModel.fetchStats(for: newPeriod)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchStats(for: selectedPeriod)
            }
        }
    }
}

struct TotalExerciseStats: View {
    let stats: ExerciseStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Toplam Değerler")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(title: "Yakılan", value: "\(Int(stats.totalCalories))", unit: "kcal")
                StatItem(title: "Antrenman", value: "\(stats.totalWorkouts)", unit: "adet")
                StatItem(title: "Süre", value: "\(Int(stats.totalDuration/60))", unit: "dk")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct CaloriesBurnedChart: View {
    let data: [CaloriesDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Yakılan Kalori")
                .font(.headline)
            
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Kalori", point.calories)
                    )
                    .foregroundStyle(.blue)
                    
                    PointMark(
                        x: .value("Tarih", point.date),
                        y: .value("Kalori", point.calories)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
        }
    }
}

struct ExerciseDistributionChart: View {
    let data: [ExerciseTypeData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Egzersiz Dağılımı")
                .font(.headline)
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Kalori", item.calories),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Tip", item.name))
            }
        }
    }
} 