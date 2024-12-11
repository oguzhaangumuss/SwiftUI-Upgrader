import SwiftUI

struct WeightHistoryView: View {
    let initialWeight: Double
    let currentWeight: Double
    let joinDate: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Kilo Geçmişi")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Başlangıç")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", initialWeight)) kg")
                        .font(.title3)
                    Text(joinDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack {
                    Text("Güncel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", currentWeight)) kg")
                        .font(.title3)
                    Text("Bugün")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            let change = currentWeight - initialWeight
            Text(change > 0 ? "▲" : change < 0 ? "▼" : "●")
                .foregroundColor(change > 0 ? .red : change < 0 ? .green : .gray)
            + Text(" \(abs(change), specifier: "%.1f") kg")
                .foregroundColor(change > 0 ? .red : change < 0 ? .green : .gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
} 

