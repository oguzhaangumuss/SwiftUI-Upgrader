import SwiftUI
import Charts

struct DailyBalanceCard: View {
    let consumed: Double
    let burned: Double
    let goal: Int?
    
    private var net: Double {
        consumed - burned
    }
    
    private var progress: Double {
        guard let goal = goal, goal > 0 else { return 0 }
        return min(net / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Günlük Kalori Dengesi")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(consumed))")
                        .font(.title2)
                        .bold()
                    Text("Alınan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(burned))")
                        .font(.title2)
                        .bold()
                    Text("Yakılan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(net))")
                        .font(.title2)
                        .bold()
                        .foregroundColor(net > 0 ? .red : .green)
                    Text("Net")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let goal = goal {
                VStack(spacing: 4) {
                    ProgressView(value: progress) {
                        HStack {
                            Text("Hedef: \(goal) kcal")
                            Spacer()
                            Text("\(Int(progress * 100))%")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct WeeklyBalanceChart: View {
    let data: [DayCalories]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Haftalık Özet")
                .font(.headline)
            
            Chart {
                ForEach(data) { day in
                    BarMark(
                        x: .value("Tarih", day.date, unit: .day),
                        y: .value("Alınan", day.consumed)
                    )
                    .foregroundStyle(.blue)
                    
                    BarMark(
                        x: .value("Tarih", day.date, unit: .day),
                        y: .value("Yakılan", -day.burned)
                    )
                    .foregroundStyle(.red)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct FoodDistributionChart: View {
    let data: [FoodData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Yiyecek Dağılımı")
                .font(.headline)
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Kalori", item.calories),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Yiyecek", item.name))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct ActivityDistributionChart: View {
    let data: [ActivityData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Aktivite Dağılımı")
                .font(.headline)
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Kalori", item.calories),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Aktivite", item.name))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
} 
