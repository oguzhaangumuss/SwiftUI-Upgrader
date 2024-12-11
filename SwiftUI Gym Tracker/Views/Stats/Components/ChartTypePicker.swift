import SwiftUI

struct ChartTypePicker: View {
    @Binding var selection: ChartType
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button {
                        withAnimation {
                            selection = type
                        }
                    } label: {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection == type ? Color.blue : Color.blue.opacity(0.1))
                            .foregroundColor(selection == type ? .white : .blue)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ChartTypePicker(selection: .constant(.activity))
} 