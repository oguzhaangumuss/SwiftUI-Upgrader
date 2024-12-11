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
            case .calories:
                return "kcal"
            case .workouts:
                return "adet"
            case .weight:
                return "kg"
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
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CustomMetric.allCases, id: \.self) { metric in
                            Toggle(metric.rawValue, isOn: binding(for: metric))
                                .toggleStyle(.button)
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            // Grafik
            if data.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                Chart(data) { item in
                    LineMark(
                        x: .value("Tarih", item.date),
                        y: .value("Değer", item.value)
                    )
                    .foregroundStyle(by: .value("Tür", item.type))
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
    
    private func binding(for metric: CustomMetric) -> Binding<Bool> {
        Binding(
            get: { selectedMetrics.contains(metric) },
            set: { isSelected in
                if isSelected {
                    selectedMetrics.insert(metric)
                } else {
                    selectedMetrics.remove(metric)
                }
            }
        )
    }
}

#Preview {
    CustomDateRangeChart(data: [])
} 