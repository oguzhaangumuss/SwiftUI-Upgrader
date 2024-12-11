import SwiftUI
import Charts

struct NutritionStatsView: View {
    @StateObject private var viewModel = NutritionStatsViewModel()
    @State private var selectedPeriod: StatsPeriod = .daily
    
    enum StatsPeriod: String, CaseIterable {
        case daily = "Günlük"
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
                TotalNutritionCard(stats: viewModel.currentStats)
                
                // Grafik
                NutritionChart(data: viewModel.chartData)
                    .frame(height: 250)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            .padding()
        }
        .navigationTitle("Beslenme İstatistikleri")
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

struct TotalNutritionCard: View {
    let stats: NutritionStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Toplam Değerler")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(title: "Kalori", value: "\(Int(stats.totalCalories))", unit: "kcal")
                StatItem(title: "Protein", value: String(format: "%.1f", stats.totalProtein), unit: "g")
                StatItem(title: "Karb", value: String(format: "%.1f", stats.totalCarbs), unit: "g")
                StatItem(title: "Yağ", value: String(format: "%.1f", stats.totalFat), unit: "g")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct NutritionChart: View {
    let data: [NutritionDataPoint]
    
    var body: some View {
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