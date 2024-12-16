import SwiftUI
import FirebaseFirestore

struct WorkoutPlanView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var showingQuickStartSheet = false
    @State private var showingCreateTemplateSheet = false
    @State private var showingCreateGroupSheet = false
    @State private var showingGroupSelector = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Hızlı Başlangıç Bölümü
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
                    
                    // Antrenman Şablonları Bölümü
                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        // Şablon Grupları
                        ForEach(viewModel.templateGroups) { group in
                            TemplateGroupView(group: group, templates: viewModel.templates[group.id ?? ""] ?? []) { template in
                                selectedTemplate = template
                            }
                        }
                    }
                    
                    // Örnek Şablonlar Bölümü
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Örnek Şablonlar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.sampleTemplates) { template in
                                    TemplateCardView(template: template) {
                                        selectedTemplate = template
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
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
        }
    }
}
#Preview{
    WorkoutPlanView()
}
    
    
