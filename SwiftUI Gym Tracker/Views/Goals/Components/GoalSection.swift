import SwiftUI
struct GoalSection: View {
    let title: String
    let current: Double
    let target: Double?
    let onEdit: () -> Void
    
    private var isWeightGoal: Bool {
        title.contains("Kilo")
    }
    
    private var progress: Double {
        guard let target = target, target > 0 else { return 0 }
        
        if isWeightGoal {
            // Kilo hedefi ise özel hesaplama
            if target < current {
                // Kilo vermek istiyor
                let initialWeight = FirebaseManager.shared.currentUser?.initialWeight ?? current
                return min(max((initialWeight - current) / (initialWeight - target), 0), 1.0)
            } else if target > current {
                // Kilo almak istiyor
                let initialWeight = FirebaseManager.shared.currentUser?.initialWeight ?? current
                return min(max((current - initialWeight) / (target - initialWeight), 0), 1.0)
            } else {
                // Hedef = Şimdiki kilo, zaten hedefe ulaşmış
                return 1.0
            }
        } else {
            // Diğer hedefler için normal hesaplama
            return min(current / target, 1.0)
        }
    }
    
    var displayTitle: String {
        if isWeightGoal {
            if let target = target {
                if target < current {
                    return "Kilo Verme Hedefi"
                } else if target > current {
                    return "Kilo Alma Hedefi"
                }
            }
        }
        return title
    }
    
    var formattedValues: String {
        if isWeightGoal {
            if let target = target {
                return "\(String(format: "%.1f", current))/\(String(format: "%.1f", target))"
            }
        }
        
        if let target = target {
            return "\(Int(current))/\(Int(target))"
        }
        
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(displayTitle)
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
                        Text(formattedValues)
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
