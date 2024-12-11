import SwiftUI

struct ProgressSummaryView: View {
    let progress: GoalsViewModel.Progress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İlerleme Özeti")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Kalori Hedefi İlerlemesi
                if let calorieProgress = progress.calorieProgress {
                    ProgressRow(
                        title: "Kalori",
                        current: calorieProgress.current,
                        target: calorieProgress.target,
                        unit: "kcal",
                        color: .orange
                    )
                }
                
                // Antrenman Hedefi İlerlemesi
                if let workoutProgress = progress.workoutProgress {
                    ProgressRow(
                        title: "Antrenman",
                        current: workoutProgress.current,
                        target: workoutProgress.target,
                        unit: "adet",
                        color: .blue
                    )
                }
                
                // Kilo Hedefi İlerlemesi
                if let weightProgress = progress.weightProgress {
                    ProgressRow(
                        title: "Kilo",
                        current: weightProgress.current,
                        target: weightProgress.target,
                        unit: "kg",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct ProgressRow: View {
    let title: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(current))/\(Int(target)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(color)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4),
                    alignment: .leading
                )
        }
    }
}

#Preview {
    let previewProgress = GoalsViewModel.Progress(
        calorieProgress: .init(current: 1500, target: 2000),
        workoutProgress: .init(current: 3, target: 5),
        weightProgress: .init(current: 75, target: 70)
    )
    
    return ProgressSummaryView(progress: previewProgress)
        .padding()
} 