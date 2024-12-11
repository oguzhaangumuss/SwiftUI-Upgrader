import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAccountAlert = false
    let currentUser = FirebaseManager.shared.currentUser
    
    var body: some View {
        NavigationView {
            List {
                // Profil Düzenleme
                if let user = currentUser {
                    Section {
                        NavigationLink {
                            EditProfileView(user: user)
                        } label: {
                            Label("Profili Düzenle", systemImage: "person.fill")
                        }
                    }
                }
                
                // Admin Paneli (sadece adminler için)
                if currentUser?.isAdmin == true {
                    Section {
                        NavigationLink {
                            AdminPanelView()
                        } label: {
                            Label("Admin Paneli", systemImage: "shield.fill")
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
                        try? FirebaseManager.shared.auth.signOut()
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
            .alert("Hesabı Sil", isPresented: $showingDeleteAccountAlert) {
                Button("Sil", role: .destructive) {
                    deleteAccount()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    private func deleteAccount() {
        // Hesap silme işlemi
    }
} 