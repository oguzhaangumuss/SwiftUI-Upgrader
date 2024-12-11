import SwiftUI
import Charts

struct CalorieBalanceChart: View {
    let data: [StatsViewModel.CalorieData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kalori Dengesi")
                .font(.headline)
            
            if data.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Alınan", point.consumed)
                    )
                    .foregroundStyle(.orange)
                    
                    LineMark(
                        x: .value("Tarih", point.date),
                        y: .value("Yakılan", point.burned)
                    )
                    .foregroundStyle(.green)
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