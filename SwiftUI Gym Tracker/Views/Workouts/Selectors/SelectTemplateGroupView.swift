import SwiftUI

struct SelectTemplateGroupView: View {
    @StateObject private var viewModel = TemplateGroupsViewModel()
    @Environment(\.dismiss) private var dismiss
    let onSelect: (WorkoutTemplateGroup) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.groups) { group in
                    Button {
                        onSelect(group)
                        dismiss()
                    } label: {
                        Text(group.name)
                    }
                }
            }
            .navigationTitle("Grup Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "Henüz grup yok",
                        systemImage: "folder.badge.plus",
                        description: Text("Önce bir grup oluşturun")
                    )
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchGroups()
            }
        }
    }
}

#Preview {
    SelectTemplateGroupView { group in
        print("Selected group: \(group.name)")
    }
} 
