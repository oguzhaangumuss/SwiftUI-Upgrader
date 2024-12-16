import SwiftUI

struct TemplateGroupView: View {
    let group: WorkoutTemplateGroup
    let templates: [WorkoutTemplate]
    let onTemplateSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.name)
                .font(.title3)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            if templates.isEmpty {
                EmptyTemplateView()
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160), spacing: 16)
                ], spacing: 16) {
                    ForEach(templates) { template in
                        TemplateCardView(template: template) {
                            onTemplateSelect(template)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct EmptyTemplateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.rectangle.dashed")
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