import SwiftUI

struct TemplateGroupsView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @StateObject private var groupsViewModel = TemplateGroupsViewModel()
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showAddGroupSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Grup başlıkları
                ForEach(groupsViewModel.groups) { group in
                    Section(header: 
                        HStack {
                            Text(group.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                // Grup düzenleme fonksiyonu gelecekte eklenebilir
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.gray)
                            }
                        }
                    ) {
                        // Grup için şablon görünümü - her grup kendi viewModel'ini ve ID'sini alıyor
                        TemplateGroupView(viewModel: groupsViewModel, groupId: group.id ?? "")
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Antrenman Şablonları")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddGroupSheet = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddGroupSheet) {
                // Grup ekleme sayfası
                NavigationView {
                    Text("Yeni Grup Ekle")
                    // Burada gerçek bir CreateTemplateGroupView ekleyebilirsiniz
                }
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
        }
        .onAppear {
            Task {
                await groupsViewModel.fetchAll()
            }
        }
    }
}

#Preview {
    TemplateGroupsView()
}

