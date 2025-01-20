import SwiftUI
import Charts

struct CustomDateRangeChart: View {
    let data: [StatsViewModel.CustomRangeData]
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    @State private var selectedMetrics = Set<CustomMetric>()
    
    enum CustomMetric: String, CaseIterable, Identifiable {
        case calories = "Kalori"
        case workouts = "Antrenman"
        case weight = "Kilo"
        
        var id: String { rawValue }
        
        var unit: String {
            switch self {
            case .calories: return "kcal"
            case .workouts: return "adet"
            case .weight: return "kg"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tarih seçici
            VStack(alignment: .leading) {
                Text("Tarih Aralığı")
                    .font(.headline)
                
                HStack {
                    DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                    Text("-")
                    DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            
            // Metrik seçici
            VStack(alignment: .leading) {
                Text("Metrikler")
                    .font(.headline)
                
                ForEach(CustomMetric.allCases) { metric in
                    Toggle(metric.rawValue, isOn: Binding(
                        get: { selectedMetrics.contains(metric) },
                        set: { isSelected in
                            if isSelected {
                                selectedMetrics.insert(metric)
                            } else {
                                selectedMetrics.remove(metric)
                            }
                        }
                    ))
                }
            }
            
            // Grafik
            if data.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(data) { item in
                        if selectedMetrics.contains(.calories) {
                            LineMark(
                                x: .value("Tarih", item.date),
                                y: .value("Kalori", item.calories)
                            )
                            .foregroundStyle(.orange)
                        }
                        
                        if selectedMetrics.contains(.workouts) {
                            LineMark(
                                x: .value("Tarih", item.date),
                                y: .value("Antrenman", Double(item.workouts))
                            )
                            .foregroundStyle(.blue)
                        }
                        
                        if selectedMetrics.contains(.weight),
                           let weight = item.weight {
                            LineMark(
                                x: .value("Tarih", item.date),
                                y: .value("Kilo", weight)
                            )
                            .foregroundStyle(.green)
                        }
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    let previewData = [
        StatsViewModel.CustomRangeData(
            date: calendar.date(byAdding: .day, value: -3, to: today)!,
            calories: 500,
            workouts: 2,
            weight: 75.5
        ),
        StatsViewModel.CustomRangeData(
            date: calendar.date(byAdding: .day, value: -2, to: today)!,
            calories: 600,
            workouts: 1,
            weight: 75.3
        ),
        StatsViewModel.CustomRangeData(
            date: calendar.date(byAdding: .day, value: -1, to: today)!,
            calories: 450,
            workouts: 3,
            weight: 75.2
        )
    ]
    
    return CustomDateRangeChart(data: previewData)
        .padding()
        .previewLayout(.sizeThatFits)
} 
