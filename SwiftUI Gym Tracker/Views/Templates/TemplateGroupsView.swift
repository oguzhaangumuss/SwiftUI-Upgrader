import SwiftUI

struct TemplateGroupsView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var selectedTemplate: WorkoutTemplate?
    
    var body: some View {
        List {
            groupsList
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(
                template: template
                
            )
        }
        .onAppear {
            Task {
                await viewModel.fetchTemplates()
            }
        }
    }
    
    // Gruplar listesi
    private var groupsList: some View {
        ForEach(viewModel.templateGroups) { group in
            groupSection(for: group)
        }
    }
    
    // Grup bölümü
    private func groupSection(for group: WorkoutTemplateGroup) -> some View {
        Section(header: Text(group.name)) {
            TemplateGroupView(
                group: group,
                templates: viewModel.templates[group.id ?? ""] ?? [],
                onTemplateSelect: { template in
                    selectedTemplate = template
                },
                onTemplateDelete: { template in
                    Task {
                        await viewModel.deleteTemplate(template)
                    }
                }
            )
        }
    }
    
    // ViewModel oluşturucu
    private func makeTemplateDetailViewModel(for template: WorkoutTemplate) -> TemplateDetailViewModel {
        let detailViewModel = TemplateDetailViewModel(template: template)
        detailViewModel.delegate = viewModel
        return detailViewModel
    }
}

#Preview {
    TemplateGroupsView()
}
