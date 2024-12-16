import SwiftUI

struct TemplateGroupsView: View {
    @StateObject private var viewModel = TemplateGroupsViewModel()
    @State private var showingNewGroup = false
    
    var body: some View {
        List {
            ForEach(viewModel.templateGroups) { group in
                Section(header: Text(group.name)) {
                    if let groupId = group.id,
                       let templates = viewModel.templates[groupId],
                       !templates.isEmpty {
                        ForEach(templates) { template in
                            NavigationLink(destination: EditTemplateView(template: template)) {
                                Text(template.name)
                            }
                        }
                    } else {
                        Text("Bu grupta henüz şablon bulunmuyor")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Antrenman Şablonları")
        .toolbar {
            Button {
                showingNewGroup = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingNewGroup) {
            NewTemplateGroupView()
        }
        .onAppear {
            Task {
                await viewModel.fetchTemplates()
            }
        }
        .refreshable {
            await viewModel.fetchTemplates()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.templateGroups.isEmpty {
                ContentUnavailableView(
                    "Henüz şablon grubu yok",
                    systemImage: "rectangle.stack.badge.plus",
                    description: Text("Yeni bir grup oluşturarak başlayın")
                )
            }
        }
    }
} 
