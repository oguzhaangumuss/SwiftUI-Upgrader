import SwiftUI
import FirebaseFirestore

struct AdminUserDetailView: View {
    let user: User
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Kişisel Bilgiler")) {
                LabeledContent("Ad", value: user.firstName)
                LabeledContent("Soyad", value: user.lastName)
                LabeledContent("E-posta", value: user.email)
                LabeledContent("Yaş", value: "\(user.age)")
            }
            
            Section(header: Text("Fiziksel Bilgiler")) {
                LabeledContent("Boy", value: "\(Int(user.height ?? 0)) cm")
                LabeledContent("Kilo", value: "\(Int(user.weight ?? 0)) kg")
                if let initialWeight = user.initialWeight {
                    LabeledContent("Başlangıç Kilosu", value: "\(Int(initialWeight)) kg")
                    LabeledContent("Kilo Değişimi", value: user.weightChangeText)
                }
            }
            
            Section(header: Text("Hedefler")) {
                if let calorieGoal = user.calorieGoal {
                    LabeledContent("Kalori Hedefi", value: "\(calorieGoal) kcal/gün")
                }
                if let workoutGoal = user.workoutGoal {
                    LabeledContent("Antrenman Hedefi", value: "\(workoutGoal) antrenman/hafta")
                }
                if let weightGoal = user.weightGoal {
                    LabeledContent("Kilo Hedefi", value: "\(Int(weightGoal)) kg")
                }
            }
            
            Section(header: Text("Hesap Durumu")) {
                Toggle("Admin Yetkisi", isOn: .constant(user.isAdmin))
                    .disabled(true)
                
                if let joinDate = user.joinDate {
                    LabeledContent("Üyelik Tarihi", value: joinDate.dateValue().formatted(date: .long, time: .omitted))
                }
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Kullanıcı Detayı")
        .toolbar {
            Menu {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Hesabı Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .alert("Hesabı Sil", isPresented: $showingDeleteAlert) {
            Button("Sil", role: .destructive) {
                deleteUser()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu kullanıcının hesabını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
    }
    
    private func deleteUser() {
        guard let userId = user.id else {
            errorMessage = "Kullanıcı ID'si bulunamadı"
            return
        }
        
        Task {
            do {
                // Kullanıcının verilerini sil
                try await FirebaseManager.shared.firestore
                    .collection("users")
                    .document(userId)
                    .delete()
                
                dismiss()
            } catch {
                errorMessage = "Kullanıcı silinirken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
} 