import SwiftUI
import FirebaseAuth

class SettingsViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        fetchUserData()
    }
    
    func fetchUserData() {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        isLoading = true
        
        Task {
            do {
                let doc = try await FirebaseManager.shared.firestore
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                await MainActor.run {
                    self.user = try? doc.data(as: User.self)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Kullanıcı bilgileri alınamadı"
                    self.isLoading = false
                }
            }
        }
    }
    
    func signOut() {
        isLoading = true
        
        Task {
            do {
                try FirebaseManager.shared.auth.signOut()
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Çıkış yapılırken hata oluştu"
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                // Önce Firestore verilerini sil
                try await FirebaseManager.shared.firestore
                    .collection("users")
                    .document(user.uid)
                    .delete()
                
                // Sonra kullanıcı hesabını sil
                try await user.delete()
                
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Hesap silinirken hata oluştu"
                    self.isLoading = false
                }
            }
        }
    }
} 