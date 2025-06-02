import SwiftUI
import FirebaseCore

struct TemplateCardView: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: getIconForTemplate(template.name))
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.primaryColor)
                        .clipShape(Circle())
                    
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        if !template.exercises.isEmpty {
                            Text("\(template.exercises.count) egzersiz")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Last updated text
                        Text("Son güncelleme: \(formatDate(template.updatedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryColor.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.primaryColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper to get an appropriate icon based on template name
    private func getIconForTemplate(_ name: String) -> String {
        let lowercaseName = name.lowercased()
        
        if lowercaseName.contains("upper") || lowercaseName.contains("üst") {
            return "figure.arms.open"
        } else if lowercaseName.contains("lower") || lowercaseName.contains("alt") || lowercaseName.contains("leg") {
            return "figure.run"
        } else if lowercaseName.contains("chest") || lowercaseName.contains("göğüs") {
            return "figure.strengthtraining.traditional"
        } else if lowercaseName.contains("back") || lowercaseName.contains("sırt") {
            return "figure.gymnastics"
        } else if lowercaseName.contains("arm") || lowercaseName.contains("kol") {
            return "figure.mind.and.body"
        } else if lowercaseName.contains("shoulder") || lowercaseName.contains("omuz") {
            return "figure.boxing"
        } else if lowercaseName.contains("cardio") || lowercaseName.contains("kardiyo") {
            return "figure.hiking"
        } else {
            return "dumbbell"  // Default icon
        }
    }
    
    // Format date to a readable string
    private func formatDate(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}


