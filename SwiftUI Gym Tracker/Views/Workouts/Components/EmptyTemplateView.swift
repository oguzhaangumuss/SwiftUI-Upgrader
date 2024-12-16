import SwiftUI

private struct EmptyTemplateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.rectangle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Bir şablon oluşturun")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
} 
