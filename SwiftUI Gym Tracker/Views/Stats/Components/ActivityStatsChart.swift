import SwiftUI
import Charts

struct ActivityStatsChart: View {
    let data: [StatsViewModel.ActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktivite Dağılımı")
                .font(.headline)
            
            if data.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 20) {
                    // Pasta Grafik
                    Chart {
                        ForEach(data) { activity in
                            SectorMark(
                                angle: .value("Kalori", activity.calories),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("Aktivite", activity.name))
                        }
                    }
                    .frame(height: 200)
                    .chartLegend(position: .bottom)
                    
                    // Aktivite Listesi
                    VStack(spacing: 12) {
                        ForEach(data) { activity in
                            HStack {
                                Text(activity.name)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("\(Int(activity.calories)) kcal")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Text(formatDuration(activity.duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours) sa \(minutes) dk"
        } else {
            return "\(minutes) dk"
        }
    }
}

struct ActivityStatsChart_Previews: PreviewProvider {
    static var previews: some View {
        let previewData = [
            StatsViewModel.ActivityData(
                name: "Koşu",
                duration: 3600,
                calories: 400
            ),
            StatsViewModel.ActivityData(
                name: "Ağırlık",
                duration: 2700,
                calories: 300
            )
        ]
        
        ActivityStatsChart(data: previewData)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 