import SwiftUI

struct EmptyStateView: View {
    let image: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: image)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyStateView(image: "dumbbell", message: "Bu tarihte antrenman bulunmuyor")
} 