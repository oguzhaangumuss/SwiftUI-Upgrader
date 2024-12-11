import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    let user: User
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var age: String
    @State private var height: String
    @State private var weight: String
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _age = State(initialValue: String(user.age))
        _height = State(initialValue: String(user.height))
        _weight = State(initialValue: String(user.weight))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)
                    TextField("Yaş", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Fiziksel Bilgiler")) {
                    TextField("Boy (cm)", text: $height)
                        .keyboardType(.decimalPad)
                    TextField("Kilo (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { updateProfile() }
                    .disabled(isLoading)
            )
        }
    }
    
    private func updateProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = ""
        
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "age": Int(age) ?? 0,
            "height": Double(height) ?? 0.0,
            "weight": Double(weight) ?? 0.0,
            "updatedAt": Timestamp()
        ]
        
        Task {
            do {
                try await FirebaseManager.shared.updateUser(userId: userId, data: userData)
                dismiss()
            } catch {
                errorMessage = "Profil güncellenirken hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
} 
