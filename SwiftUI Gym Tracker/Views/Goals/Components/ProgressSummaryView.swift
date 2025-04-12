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
                    WeightProgressRow(
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

// Özel kilo ilerleme satırı
private struct WeightProgressRow: View {
    let current: Double
    let target: Double
    let unit: String
    let color: Color
    
    private var isWeightLoss: Bool {
        target < current // Hedef, mevcut kilodan düşükse kilo vermek istiyor
    }
    
    private var isWeightGain: Bool {
        target > current // Hedef, mevcut kilodan yüksekse kilo almak istiyor
    }
    
    private var progress: Double {
        if isWeightLoss {
            // Kilo vermek isteniyorsa: Başlangıç - Şimdiki / Başlangıç - Hedef
            // Örnek: 90 kilodan 80 kiloya düşmek istiyor, şu an 85 kilo
            // İlerleme: (90 - 85) / (90 - 80) = 5 / 10 = 0.5 (%50)
            let initialWeight = FirebaseManager.shared.currentUser?.initialWeight ?? current
            return min(max((initialWeight - current) / (initialWeight - target), 0), 1.0)
        } else if isWeightGain {
            // Kilo almak isteniyorsa: Şimdiki - Başlangıç / Hedef - Başlangıç
            // Örnek: 70 kilodan 80 kiloya çıkmak istiyor, şu an 75 kilo
            // İlerleme: (75 - 70) / (80 - 70) = 5 / 10 = 0.5 (%50)
            let initialWeight = FirebaseManager.shared.currentUser?.initialWeight ?? current
            return min(max((current - initialWeight) / (target - initialWeight), 0), 1.0)
        } else {
            // Hedef = Şimdiki kilo, zaten hedefe ulaşmış
            return 1.0
        }
    }
    
    var weightGoalText: String {
        if isWeightLoss {
            return "Kilo Verme Hedefi"
        } else if isWeightGain {
            return "Kilo Alma Hedefi"
        } else {
            return "Kilo Hedefi"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(weightGoalText)
                    .font(.subheadline)
                Spacer()
                Text("\(String(format: "%.1f", current))/\(String(format: "%.1f", target)) \(unit)")
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

