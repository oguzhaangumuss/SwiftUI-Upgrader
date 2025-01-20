import SwiftUI
import FirebaseCore

struct TemplateGroupView: View {
    let group: WorkoutTemplateGroup
    let templates: [WorkoutTemplate]
    let onTemplateSelect: (WorkoutTemplate) -> Void
    let onTemplateDelete: (WorkoutTemplate) -> Void
    @State private var showingCreateTemplate = false
    
    // Grid için sabit değerler
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        if templates.isEmpty {
            // Boş durum görünümü - tıklanabilir
            Button {
                showingCreateTemplate = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.primaryColor)
                    
                    Text("Bu grupta henüz şablon yok")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 180) // Sabit yükseklik
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView(selectedGroupId: group.id)
            }
        } else {
            // Template grid'i
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(templates) { template in
                    TemplateCardView(
                        template: template,
                        onTap: {
                            onTemplateSelect(template)
                        }
                    )
                    .frame(height: 180)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct EmptyTemplateView: View {
    let group: WorkoutTemplateGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: "plus.rectangle.dashed")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                
                Text("\(group.name) için şablon oluşturun")
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
} 

#Preview {
    TemplateGroupView(
        group: WorkoutTemplateGroup(
            id: "1", 
            userId: "test-user-id",
            name: "Test Group",
            createdAt: Timestamp(),
            updatedAt: Timestamp()
        ), 
        templates: [], 
        onTemplateSelect: { _ in },
        onTemplateDelete: { _ in }
    )
}
