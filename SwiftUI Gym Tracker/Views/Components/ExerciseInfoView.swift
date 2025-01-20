import SwiftUI

struct ExerciseInfoView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    HStack {
        ExerciseInfoView(title: "Set", value: "3")
        ExerciseInfoView(title: "Tekrar", value: "12")
        ExerciseInfoView(title: "Kilo", value: "20 kg")
    }
    .padding()
} 
