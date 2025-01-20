import SwiftUI

struct StatsAndReportsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedChart: ChartType = .activity
    @State private var selectedPeriod: StatsPeriod = .weekly
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ChartControlsView(selectedChart: $selectedChart, selectedPeriod: $selectedPeriod)
                ChartContentView(viewModel: viewModel, selectedChart: selectedChart)
            }
            .padding(.vertical)
        }
        .navigationTitle("İstatistikler")
        .onAppear {
            Task {
                await viewModel.fetchStats(for: selectedPeriod)
            }
        }
        .onChange(of: selectedPeriod) { newPeriod in
            Task {
                await viewModel.fetchStats(for: newPeriod)
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Chart Controls View
struct ChartControlsView: View {
    @Binding var selectedChart: ChartType
    @Binding var selectedPeriod: StatsPeriod
    
    var body: some View {
        VStack(spacing: 16) {
            ChartTypePicker(selection: $selectedChart)
            
            Picker("Periyot", selection: $selectedPeriod) {
                Text("Günlük").tag(StatsPeriod.daily)
                Text("Haftalık").tag(StatsPeriod.weekly)
                Text("Aylık").tag(StatsPeriod.monthly)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}

// MARK: - Chart Content View
struct ChartContentView: View {
    let viewModel: StatsViewModel
    let selectedChart: ChartType
    
    var body: some View {
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
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ProgressView()
            .background(Color.black.opacity(0.1))
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        StatsAndReportsView()
    }
} 
