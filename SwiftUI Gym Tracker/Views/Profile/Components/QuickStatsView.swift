import SwiftUI
struct QuickStatsView: View {
    let stats: ProfileViewModel.DailyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(Int(stats.burnedCalories))",
                    title: "Yakılan",
                    color: .orange
                )
                
                StatCard(
                    icon: "figure.walk",
                    value: "\(stats.workoutCount)",
                    title: "Antrenman",
                    color: .blue
                )
                
                if let weightChange = stats.weightChange {
                    StatCard(
                        icon: "arrow.up.arrow.down",
                        value: String(format: "%.1f", abs(weightChange)),
                        title: weightChange > 0 ? "Kilo +" : "Kilo -",
                        color: weightChange > 0 ? .red : .green
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    QuickStatsView(stats: ProfileViewModel.DailyStats(
        consumedCalories: 2000,
        burnedCalories: 500,
        workoutCount: 2,
        weightChange: -0.5
    ))
} 
