import SwiftUI

struct StatsAndReportsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedChart: ChartType = .activity
    @State private var selectedPeriod: StatsPeriod = .weekly
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Grafik Seçim Butonları
                ChartTypePicker(selection: $selectedChart)
                
                // Periyot Seçici
                Picker("Periyot", selection: $selectedPeriod) {
                    Text("Günlük").tag(StatsPeriod.daily)
                    Text("Haftalık").tag(StatsPeriod.weekly)
                    Text("Aylık").tag(StatsPeriod.monthly)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Seçilen Grafik
                Group {
                    switch selectedChart {
                    case .activity:
                        ActivityStatsChart(data: viewModel.activityData)
                    case .calories:
                        CalorieBalanceChart(data: viewModel.calorieData)
                    case .weight:
                        WeightProgressChart(data: viewModel.weightData)
                    case .custom:
                        CustomDateRangeChart(data: viewModel.customRangeData)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("İstatistikler")
        .onChange(of: selectedPeriod) { _ in
            Task {
                await viewModel.fetchStats(for: selectedPeriod)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchStats(for: selectedPeriod)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .background(Color.black.opacity(0.1))
            }
        }
    }
}

#Preview {
    NavigationView {
        StatsAndReportsView()
    }
} 
