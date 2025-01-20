import SwiftUI
import Charts

struct ActivityStatsChart: View {
    let data: [StatsViewModel.ActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktivite İstatistikleri")
                .font(.headline)
            
            if data.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 20) {
                    // Çubuk Grafik
                    Chart {
                        ForEach(data, id: \.date) { activity in
                            BarMark(
                                x: .value("Tarih", activity.date, unit: .day),
                                y: .value("Antrenman", activity.workoutCount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday())
                        }
                    }
                    
                    // Aktivite Özeti
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Toplam Antrenman")
                                    .font(.subheadline)
                                Text("\(totalWorkouts)")
                                    .font(.title2)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Toplam Süre")
                                    .font(.subheadline)
                                Text(formatTotalDuration())
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // Toplam antrenman sayısı
    private var totalWorkouts: Int {
        data.reduce(0) { $0 + $1.workoutCount }
    }
    
    // Toplam süre
    private func formatTotalDuration() -> String {
        let totalDuration = data.reduce(0.0) { $0 + $1.duration }
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) / 60 % 60
        
        if hours > 0 {
            return "\(hours) sa \(minutes) dk"
        } else {
            return "\(minutes) dk"
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    
    // Örnek veriler
    let previewData = [
        StatsViewModel.ActivityData(
            date: calendar.date(byAdding: .day, value: -3, to: today)!,
            workoutCount: 2,
            duration: 3600
        ),
        StatsViewModel.ActivityData(
            date: calendar.date(byAdding: .day, value: -2, to: today)!,
            workoutCount: 1,
            duration: 1800
        ),
        StatsViewModel.ActivityData(
            date: calendar.date(byAdding: .day, value: -1, to: today)!,
            workoutCount: 3,
            duration: 5400
        ),
        StatsViewModel.ActivityData(
            date: today,
            workoutCount: 2,
            duration: 3600
        )
    ]
    
    return ActivityStatsChart(data: previewData)
        .padding()
        .previewLayout(.sizeThatFits)
} 
