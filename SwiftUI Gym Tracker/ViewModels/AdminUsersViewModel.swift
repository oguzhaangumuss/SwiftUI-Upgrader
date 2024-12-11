import SwiftUI
import FirebaseFirestore

class AdminUsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    
    private let db = FirebaseManager.shared.firestore
    
    init() {
        Task {
            await fetchUsers()
        }
    }
    
    @MainActor
    func fetchUsers() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("users").getDocuments()
            print("Bulunan kullanıcı sayısı: \(snapshot.documents.count)")
            
            users = snapshot.documents.compactMap { document -> User? in
                do {
                    let user = try document.data(as: User.self)
                    print("Dönüştürülen kullanıcı: \(user.fullName)")
                    return user
                } catch {
                    print("❌ Kullanıcı dönüştürme hatası: \(error)")
                    print("❌ Döküman verisi: \(document.data())")
                    return nil
                }
            }
            
            print("Toplam yüklenen kullanıcı: \(users.count)")
        } catch {
            print("❌ Kullanıcılar getirilemedi: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func toggleAdmin(for user: User, isAdmin: Bool) async {
        guard let userId = user.id,
              let index = users.firstIndex(where: { $0.id == user.id }) else {
            print("❌ Kullanıcı ID'si bulunamadı")
            return
        }
        
        do {
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "isAdmin": isAdmin,
                    "updatedAt": Timestamp()
                ])
            
            // Yerel state'i güncelle
            var updatedUser = user
            updatedUser.isAdmin = isAdmin
            users[index] = updatedUser
            
        } catch {
            print("Admin durumu güncellenemedi: \(error)")
        }
    }
} 