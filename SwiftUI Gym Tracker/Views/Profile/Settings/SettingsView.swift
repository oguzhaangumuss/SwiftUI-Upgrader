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
                Section("Profil") {
                    if let user = currentUser {
                        NavigationLink {
                            EditProfileView(user: user)
                        } label: {
                            Label("Profili Düzenle", systemImage: "person.circle")
                        }
                    }
                }
                
                // Admin Paneli (sadece adminler için)
                if currentUser?.isAdmin == true {
                    Section("Yönetim") {
                        NavigationLink {
                            AdminPanelView()
                        } label: {
                            Label("Admin Paneli", systemImage: "shield.fill")
                        }
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
        // Hesap silme işlemi burada implement edilecek
        guard let user = FirebaseManager.shared.auth.currentUser else { return }
        
        // Kullanıcının verilerini sil
        let db = FirebaseManager.shared.firestore
        db.collection("users").document(user.uid).delete { error in
            if let error = error {
                print("❌ Kullanıcı verileri silinirken hata: \(error.localizedDescription)")
            }
        }
        
        // Firebase Auth hesabını sil
        user.delete { error in
            if let error = error {
                print("❌ Hesap silinirken hata: \(error.localizedDescription)")
            }
        }
    }
} 
