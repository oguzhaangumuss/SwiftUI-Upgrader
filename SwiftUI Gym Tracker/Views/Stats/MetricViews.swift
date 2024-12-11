import SwiftUI
import Charts

struct CaloriesMetricView: View {
    let data: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Toplam")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(data["total"] as? Double ?? 0)) kcal")
                        .font(.title3)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Ortalama")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(data["average"] as? Double ?? 0)) kcal/gün")
                        .font(.title3)
                }
            }
        }
    }
}

struct WorkoutsMetricView: View {
    let data: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Toplam: \(data["total"] as? Int ?? 0) antrenman")
                .font(.title3)
            
            if let byType = data["byType"] as? [String: Int] {
                Chart(Array(byType), id: \.key) { item in
                    BarMark(
                        x: .value("Sayı", item.value),
                        y: .value("Tür", item.key)
                    )
                }
                .frame(height: 100)
            }
        }
    }
}

struct WeightMetricView: View {
    let data: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Başlangıç")
                        .font(.caption)
                    Text("\(String(format: "%.1f", data["start"] as? Double ?? 0)) kg")
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Son")
                        .font(.caption)
                    Text("\(String(format: "%.1f", data["end"] as? Double ?? 0)) kg")
                }
            }
            
            if let change = data["change"] as? Double {
                HStack {
                    Text("Değişim:")
                    Text(String(format: "%+.1f kg", change))
                        .foregroundColor(change > 0 ? .red : .green)
                }
            }
        }
    }
}

struct PersonalBestsMetricView: View {
    let data: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(data.sorted { $0.value > $1.value }), id: \.key) { item in
                HStack {
                    Text(item.key)
                    Spacer()
                    Text("\(Int(item.value)) kg")
                        .bold()
                }
            }
        }
    }
} 