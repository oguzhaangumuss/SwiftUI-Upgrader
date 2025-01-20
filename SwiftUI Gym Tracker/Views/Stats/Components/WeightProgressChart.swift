import SwiftUI
import Charts

struct WeightProgressChart: View {
    let data: [StatsViewModel.WeightData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kilo Takibi")
                .font(.headline)
            
            if data.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Kilo", point.weight)
                    )
                    .symbol(by: .value("Kilo", point.weight))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
} 
