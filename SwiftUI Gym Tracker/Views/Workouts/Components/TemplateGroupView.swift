import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct TemplateGroupView: View {
    // Belirli bir grubun şablonlarını göstermek için gerekli parametreler
    @ObservedObject var viewModel: TemplateGroupsViewModel
    let groupId: String
    
    // Durum değişkenleri
    @State private var showingAddTemplateSheet = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    init(viewModel: TemplateGroupsViewModel, groupId: String) {
        self.viewModel = viewModel
        self.groupId = groupId
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Grup için şablonlar var mı kontrol et
            if let templates = viewModel.templates[groupId], !templates.isEmpty {
                templatesGridView(templates: templates)
            } else {
                emptyGroupView
            }
        }
        .sheet(isPresented: $showingAddTemplateSheet) {
            NavigationView {
                CreateTemplateView(selectedGroupId: groupId)
            }
        }
        .sheet(item: $selectedTemplate) { template in
            NavigationView {
                TemplateDetailView(template: template)
            }
        }
    }
    
    // Boş grup görünümü
    private var emptyGroupView: some View {
        VStack(spacing: 20) {
            Text("Bu grupta henüz şablon bulunmuyor")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddTemplateSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Şablon Ekle")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppTheme.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: AppTheme.primaryColor.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // Şablonlar grid görünümü - sadece belirli bir grup için
    private func templatesGridView(templates: [WorkoutTemplate]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            // Add Template Button
            addTemplateButton
            
            // Template Cards - Sadece bu grup için
            ForEach(templates) { template in
                TemplateCardView(template: template) {
                    selectedTemplate = template
                }
                .transition(.scale)
            }
        }
        .padding(16)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: templates.count)
    }
    
    private var addTemplateButton: some View {
        Button(action: {
            showingAddTemplateSheet = true
        }) {
            VStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.primaryColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppTheme.primaryColor)
                    )
                
                Text("Yeni Şablon")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Ekle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.primaryColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Önizleme için yardımcı bileşen
struct TemplateGroupViewPreview: View {
    @StateObject private var viewModel = TemplateGroupsViewModel()
    let groupId: String
    
    var body: some View {
        TemplateGroupView(viewModel: viewModel, groupId: groupId)
            .onAppear {
                Task {
                    await viewModel.fetchAll()
                }
            }
    }
}

#Preview {
    NavigationStack {
        TemplateGroupViewPreview(groupId: "default_preview")
    }
}
