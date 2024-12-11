import SwiftUI
struct NavigationButtonsView: View {
    var body: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: StatsAndReportsView()) {
                MenuButton(
                    title: "İstatistik ve Raporlar",
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }
            
            NavigationLink(destination: GoalsView()) {
                MenuButton(
                    title: "Hedeflerim",
                    icon: "target",
                    color: .orange
                )
            }
            
            NavigationLink(destination: UserPerformanceView()) {
                MenuButton(
                    title: "İlerleme ve Performans",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
        }
        .padding()
    }
}

private struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 
