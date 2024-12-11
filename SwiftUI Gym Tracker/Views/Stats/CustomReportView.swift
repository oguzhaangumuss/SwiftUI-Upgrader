import SwiftUI

struct CustomReportView: View {
    @StateObject private var viewModel = CustomReportViewModel()
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedMetrics = Set<ReportMetric>()
    
    enum ReportMetric: String, CaseIterable {
        case caloriesBurned = "Yakılan Kalori"
        case workouts = "Antrenman Sayısı"
        case weight = "Kilo Değişimi"
        case personalBests = "Kişisel Rekorlar"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Tarih Aralığı")) {
                DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)
                DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
            }
            
            Section(header: Text("Metrikler")) {
                ForEach(ReportMetric.allCases, id: \.self) { metric in
                    Toggle(metric.rawValue, isOn: binding(for: metric))
                }
            }
            
            if !selectedMetrics.isEmpty {
                Section(header: Text("Rapor")) {
                    CustomReportContent(
                        startDate: startDate,
                        endDate: endDate,
                        metrics: Array(selectedMetrics)
                    )
                }
            }
        }
        .navigationTitle("Özel Rapor")
    }
    
    private func binding(for metric: ReportMetric) -> Binding<Bool> {
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
