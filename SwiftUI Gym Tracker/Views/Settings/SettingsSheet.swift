import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    // Profil Düzenleme
                    if let user = viewModel.user {
                        Section {
                            NavigationLink {
                                EditProfileView(user: user)
                            } label: {
                                Label("Profili Düzenle", systemImage: "person.fill")
                            }
                        }
                    }
                    
                    // Hesap İşlemleri
                    Section {
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
        }
    }
}

#Preview {
    SettingsSheet()
} 
