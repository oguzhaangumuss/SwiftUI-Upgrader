import SwiftUI
import FirebaseFirestore

struct WorkoutPlanView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showingQuickStartSheet = false
    @State private var showingCreateTemplateSheet = false
    @State private var showingCreateGroupSheet = false
    @State private var showingGroupSelector = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var collapsedGroups: Set<String> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    QuickStartSectionView(showingQuickStartSheet: $showingQuickStartSheet)
                    
                    // Antrenman Şablonları Bölümü
                    VStack(alignment: .leading, spacing: 16) {
                        TemplateHeaderView(
                            showingCreateTemplateSheet: $showingCreateTemplateSheet,
                            showingCreateGroupSheet: $showingCreateGroupSheet
                        )
                        
                        TemplateGroupListView(
                            viewModel: viewModel,
                            selectedTemplate: $selectedTemplate,
                            collapsedGroups: $collapsedGroups
                        )
                    }
                    
                    WorkoutHistoryView()
                }
            }
            .navigationTitle("Antrenman'a Başla")
            .sheet(isPresented: $showingQuickStartSheet) {
                QuickStartWorkoutView()
            }
            .sheet(isPresented: $showingCreateTemplateSheet) {
                CreateTemplateView()
            }
            .sheet(isPresented: $showingCreateGroupSheet) {
                CreateTemplateGroupView()
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
            .sheet(isPresented: $showingGroupSelector) {
                SelectTemplateGroupView { group in
                    showingCreateTemplateSheet = true
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchTemplates()
                }
            }
        }
    }
    
    private func makeTemplateDetailViewModel(for template: WorkoutTemplate) -> TemplateDetailViewModel {
        let viewModel = TemplateDetailViewModel(template: template)
        viewModel.delegate = self.viewModel
        return viewModel
    }
}

// Grup Listesi View'ı
private struct TemplateGroupListView: View {
    @ObservedObject var viewModel: WorkoutPlanViewModel
    @Binding var selectedTemplate: WorkoutTemplate?
    @Binding var collapsedGroups: Set<String>
    
    var body: some View {
        ForEach($viewModel.templateGroups) { $group in
            VStack {
                GroupHeaderView(
                    group: $group,
                    isCollapsed: isGroupCollapsed(group.id ?? ""),
                    onDelete: {
                        Task {
                            await viewModel.deleteGroup(group)
                        }
                    },
                    onToggle: {
                        toggleGroup(group.id ?? "")
                    },
                    viewModel: viewModel
                )
                
                if !isGroupCollapsed(group.id ?? "") {
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
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteGroup(group)
                    }
                } label: {
                    Label("Sil", systemImage: "trash")
                }
            }
        }
    }
    
    private func isGroupCollapsed(_ groupId: String) -> Bool {
        collapsedGroups.contains(groupId)
    }
    
    private func toggleGroup(_ groupId: String) {
        if collapsedGroups.contains(groupId) {
            collapsedGroups.remove(groupId)
        } else {
            collapsedGroups.insert(groupId)
        }
    }
}

// Grup Başlığı View'ı
private struct GroupHeaderView: View {
    @Binding var group: WorkoutTemplateGroup
    let isCollapsed: Bool
    let onDelete: () -> Void
    let onToggle: () -> Void
    @State private var isEditing = false
    @State private var isLoading = false
    @ObservedObject var viewModel: WorkoutPlanViewModel
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Grup İsmi", text: $group.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    Task {
                        await viewModel.updateGroupName(group.id ?? "", newName: group.name)
                        isEditing = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            } else {
                Text(group.name)
                    .font(.headline)
            }
            
            Spacer()
            
            Menu {
                Button {
                    isEditing.toggle()
                } label: {
                    Label("Şablon Grubunu Düzenle", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Şablon Grubunu Sil", systemImage: "trash")
                }
                
                Button {
                    onToggle()
                } label: {
                    Label(isCollapsed ? "Görünümü Aç" : "Görünümü Katla",
                          systemImage: isCollapsed ? "chevron.down" : "chevron.up")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

// Antrenman Şablonları Header View'ı
private struct TemplateHeaderView: View {
    @Binding var showingCreateTemplateSheet: Bool
    @Binding var showingCreateGroupSheet: Bool
    
    var body: some View {
        HStack {
            Text("Antrenman Şablonları")
                .font(.headline)
            
            Spacer()
            
            Menu {
                Button {
                    showingCreateTemplateSheet = true
                } label: {
                    Label("Şablon oluştur", systemImage: "plus.rectangle")
                }
                
                Button {
                    showingCreateGroupSheet = true
                } label: {
                    Label("Yeni bir grup oluştur", systemImage: "folder.badge.plus")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppTheme.primaryColor)
            }
        }
        .padding(.horizontal)
    }
}

// Yeni eklenen Quick Start bölümü
private struct QuickStartSectionView: View {
    @Binding var showingQuickStartSheet: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Hızlı Başlangıç")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            Button {
                showingQuickStartSheet = true
            } label: {
                HStack {
                    Spacer()
                    Text("Egzersiz ekleyerek devam et!")
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(AppTheme.primaryColor)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}
#Preview{
    WorkoutPlanView()
}
    
    
