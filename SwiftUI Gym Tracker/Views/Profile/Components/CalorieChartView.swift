import SwiftUI
import Charts

struct CalorieChartView: View {
    let consumed: Double
    let burned: Double
    
    private var remaining: Double {
        consumed - burned
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                BarMark(
                    x: .value("Tür", "Alınan"),
                    y: .value("Kalori", consumed)
                )
                .foregroundStyle(.orange)
                
                BarMark(
                    x: .value("Tür", "Yakılan"),
                    y: .value("Kalori", burned)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 150)
            
            // Özet Bilgiler
            HStack(spacing: 20) {
                CalorieStatItem(
                    title: "Alınan",
                    value: "\(Int(consumed))",
                    color: .orange
                )
                
                CalorieStatItem(
                    title: "Yakılan",
                    value: "\(Int(burned))",
                    color: .green
                )
                
                CalorieStatItem(
                    title: "Net",
                    value: "\(Int(remaining))",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

private struct CalorieStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text("kcal")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CalorieChartView(consumed: 2000, burned: 500)
} 