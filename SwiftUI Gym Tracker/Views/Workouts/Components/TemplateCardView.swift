import SwiftUI
import FirebaseCore

struct TemplateCardView: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !template.exercises.isEmpty {
                    Text("\(template.exercises.count) egzersiz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

#Preview {
    TemplateCardView(
        template: WorkoutTemplate(
            name: "Test Template", 
            exercises: [],
            createdBy: "Test User",
            userId: "test-user-id",
            createdAt: Timestamp(),
            updatedAt: Timestamp()
        ),
        onTap: {}
    )
}
