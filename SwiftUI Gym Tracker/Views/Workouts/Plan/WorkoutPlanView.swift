import SwiftUI
import FirebaseFirestore

struct WorkoutPlanView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showingQuickStartSheet = false
    @State private var showingCreateTemplateSheet = false
    @State private var showingCreateGroupSheet = false
    @State private var showingGroupSelector = false
    @State private var selectedTemplate: WorkoutTemplate? = nil
    @State private var collapsedGroups: Set<String> = []
    @State private var groupNameToEdit: String = ""
    @State private var editingGroupId: String = ""
    @State private var isEditingGroup = false
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: TemplateGroup? = nil
    @State private var showingAddGroupSheet = false
    @State private var selectedGroupId: String = ""
    @State private var showingStartWorkoutSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Hızlı Başlangıç Bölümü
                    QuickStartSectionView(showingQuickStartSheet: $showingQuickStartSheet)
                    
                    // Antrenman Şablonları Bölümü
                    VStack(alignment: .leading, spacing: 16) {
                        TemplateHeaderView(
                            showingCreateTemplateSheet: $showingCreateTemplateSheet,
                            showingCreateGroupSheet: $showingAddGroupSheet
                        )
                        
                        if viewModel.isLoading {
                            ProgressView("Şablonlar yükleniyor...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if viewModel.groups.isEmpty {
                            emptyStateView
                        } else {
                            TemplateGroupListView(
                                viewModel: viewModel,
                                selectedTemplate: $selectedTemplate,
                                collapsedGroups: $collapsedGroups
                            )
                        }
                    }
                    
                    // Antrenman Geçmişi Bölümü
                    WorkoutCalendarHistoryView()
                }
                .padding(.vertical)
            }
            .navigationTitle("Antrenman'a Başla")
            .sheet(isPresented: $showingQuickStartSheet) {
                QuickStartWorkoutView()
            }
            .sheet(isPresented: $showingCreateTemplateSheet) {
                if !selectedGroupId.isEmpty {
                    CreateTemplateView(selectedGroupId: selectedGroupId)
                } else {
                    CreateTemplateView()
                }
            }
            .sheet(isPresented: $showingAddGroupSheet) {
                AddTemplateGroupView(onSave: { newGroupName in
                    Task {
                        await viewModel.addGroup(name: newGroupName)
                    }
                })
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
            .sheet(isPresented: $showingStartWorkoutSheet) {
                if let template = selectedTemplate {
                    StartWorkoutFromTemplateView(template: template)
                }
            }
            .confirmationDialog(
                "Grubu Yeniden Adlandır",
                isPresented: $isEditingGroup,
                actions: {
                    TextField("Grup Adı", text: $groupNameToEdit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button("Kaydet", action: {
                        Task {
                            if !groupNameToEdit.isEmpty {
                                await viewModel.renameGroup(id: editingGroupId, newName: groupNameToEdit)
                            }
                            isEditingGroup = false
                        }
                    })
                    
                    Button("İptal", role: .cancel) {
                        isEditingGroup = false
                    }
                }
            )
            .alert("Grubu Sil", isPresented: $showingDeleteAlert) {
                Button("Sil", role: .destructive) {
                    if let group = groupToDelete, let groupId = group.id {
                        Task {
                            await viewModel.deleteGroup(id: groupId)
                        }
                    }
                }
                Button("İptal", role: .cancel) {}
            } message: {
                if let group = groupToDelete {
                    Text("'\(group.name)' grubunu ve içindeki tüm şablonları silmek istediğinize emin misiniz?")
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllGroups()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Henüz antrenman planınız yok")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Antrenman şablonlarınızı organize etmek için gruplar oluşturun")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingAddGroupSheet = true
            }) {
                Text("Grup Oluştur")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func makeTemplateDetailViewModel(for template: WorkoutTemplate) -> TemplateDetailViewModel {
        let viewModel = TemplateDetailViewModel(template: template)
        viewModel.delegate = self.viewModel
        return viewModel
    }
}

// Grup Listesi View'ı
struct TemplateGroupListView: View {
    @ObservedObject var viewModel: WorkoutPlanViewModel
    @Binding var selectedTemplate: WorkoutTemplate?
    @Binding var collapsedGroups: Set<String>
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.groups) { group in
                groupItem(for: group)
            }
        }
        .padding(.horizontal)
    }
    
    private func groupItem(for group: TemplateGroup) -> some View {
        guard let groupId = group.id else {
            return AnyView(EmptyView())
        }
        
        let isCollapsed = collapsedGroups.contains(groupId)
        let templates = viewModel.templates[groupId] ?? []
        
        return AnyView(
            VStack(spacing: 0) {
                GroupHeaderView(
                    group: group,
                    isCollapsed: isCollapsed,
                    onDelete: {
                        Task {
                            await viewModel.deleteGroup(id: groupId)
                        }
                    },
                    onToggle: {
                        toggleGroup(groupId)
                    },
                    viewModel: viewModel
                )
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(isCollapsed ? 12 : 12, corners: [.topLeft, .topRight])
                
                if !isCollapsed {
                    TemplateGroupView(viewModel: viewModel.templateGroupsViewModel, groupId: groupId)
                    .padding(.top, 8)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
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
struct GroupHeaderView: View {
    let group: TemplateGroup
    let isCollapsed: Bool
    let onDelete: () -> Void
    let onToggle: () -> Void
    @State private var isEditing = false
    @State private var editedName: String = ""
    @ObservedObject var viewModel: WorkoutPlanViewModel
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Grup İsmi", text: $editedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        editedName = group.name
                    }
                
                Button(action: {
                    if let groupId = group.id, !editedName.isEmpty {
                        Task {
                            await viewModel.renameGroup(id: groupId, newName: editedName)
                            isEditing = false
                        }
                    }
                }) {
                    Text("Kaydet")
                        .foregroundColor(.accentColor)
                }
                
                Button(action: {
                    isEditing = false
                }) {
                    Text("İptal")
                        .foregroundColor(.red)
                }
            } else {
                Button(action: onToggle) {
                    HStack {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(group.name)
                            .font(.headline)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: {
                        isEditing = true
                    }) {
                        Label("Adı Değiştir", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Grubu Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal)
    }
}

// Antrenman Şablonları Header View'ı
struct TemplateHeaderView: View {
    @Binding var showingCreateTemplateSheet: Bool
    @Binding var showingCreateGroupSheet: Bool
    
    var body: some View {
        HStack {
            Text("Antrenman Şablonları")
                .font(.title2)
                .bold()
            
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
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryColor)
            }
        }
        .padding(.horizontal)
    }
}

// Yeni tasarım ile QuickStart bölümü
struct QuickStartSectionView: View {
    @Binding var showingQuickStartSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hızlı Başlangıç")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            Button {
                showingQuickStartSheet = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Antrenman'a Başla")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Egzersiz ekleyerek devam et!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding()
                .background(LinearGradient(
                    gradient: Gradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(16)
                .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
            }
        }
    }
}

// Helper extension for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview{
    WorkoutPlanView()
}

