
import SwiftUI
struct GoalSection: View {
    let title: String
    let current: Double
    let target: Double?
    let onEdit: () -> Void
    
    private var progress: Double {
        guard let target = target, target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
            }
            
            if let target = target {
                ProgressView(value: progress) {
                    HStack {
                        Text("\(Int(current))/\(Int(target))")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .tint(.blue)
            } else {
                Text("Hedef belirlenmemiş")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 
