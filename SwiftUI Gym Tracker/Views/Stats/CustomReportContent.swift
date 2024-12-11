import SwiftUI

struct CustomReportContent: View {
    @StateObject private var viewModel = CustomReportViewModel()
    let startDate: Date
    let endDate: Date
    let metrics: [CustomReportView.ReportMetric]
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                ForEach(metrics, id: \.self) { metric in
                    switch metric {
                    case .caloriesBurned:
                        MetricRow(title: "Yakılan Kalori", value: "\(Int(viewModel.caloriesBurned)) kcal")
                    case .workouts:
                        MetricRow(title: "Antrenman Sayısı", value: "\(viewModel.workoutCount)")
                    case .weight:
                        if let weightChange = viewModel.weightChange {
                            MetricRow(title: "Kilo Değişimi", value: String(format: "%.1f kg", weightChange))
                        }
                    case .personalBests:
                        ForEach(Array(viewModel.personalBests.keys.sorted()), id: \.self) { exercise in
                            if let weight = viewModel.personalBests[exercise] {
                                MetricRow(title: exercise, value: "\(Int(weight)) kg")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchData(startDate: startDate, endDate: endDate)
            }
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    CustomReportContent(
        startDate: Date().addingTimeInterval(-7*24*60*60),
        endDate: Date(),
        metrics: [.caloriesBurned, .workouts, .weight, .personalBests]
    )
}