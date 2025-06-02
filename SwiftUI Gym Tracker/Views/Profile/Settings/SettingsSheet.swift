import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingDeleteAccountAlert = false
    @State private var showAIAssistant: Bool = true
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    // Profil Düzenleme
                    Section("Profil") {
                        NavigationLink {
                            if let user = viewModel.user {
                                EditProfileView(user: user)
                            }
                        } label: {
                            Label("Profili Düzenle", systemImage: "person.circle")
                        }
                        .disabled(viewModel.user == nil)
                    }
                    
                    // AI Asistanı Ayarları
                    Section("AI Asistanı") {
                        Toggle(isOn: $showAIAssistant) {
                            Label("AI Asistanı Görünürlüğü", systemImage: "face.smiling")
                        }
                        .onChange(of: showAIAssistant) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "showAIAssistant")
                            NotificationCenter.default.post(name: NSNotification.Name("AIAssistantVisibilityChanged"), object: nil)
                        }
                    }
                    
                    // Hesap İşlemleri
                    Section("Hesap") {
                        Button(role: .destructive) {
                            showingDeleteAccountAlert = true
                        } label: {
                            Label("Hesabı Sil", systemImage: "person.crop.circle.badge.minus")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.signOut()
                        } label: {
                            Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Section {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Kapat") { dismiss() })
            .alert("Hesabı Sil", isPresented: $showingDeleteAccountAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    viewModel.deleteAccount()
                }
            } message: {
                Text("Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
            .onAppear {
                // UserDefaults'tan AI asistanının görünürlük durumunu al
                showAIAssistant = UserDefaults.standard.object(forKey: "showAIAssistant") as? Bool ?? true
                
                Task {
                    await viewModel.fetchUserData()
                }
            }
        }
    }
} 