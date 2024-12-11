import SwiftUI
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Kişisel Bilgiler
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(spacing: 16) {
                                // Ad
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Ad")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryTextColor)
                                    
                                    TextField("Adınız", text: $firstName)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                
                                // Soyad
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Soyad")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryTextColor)
                                    
                                    TextField("Soyadınız", text: $lastName)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                
                                // Email
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("E-posta")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryTextColor)
                                    
                                    TextField("ornek@email.com", text: $email)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                
                                // Şifre
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Şifre")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryTextColor)
                                    
                                    SecureField("••••••••", text: $password)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                                
                                // Şifre Tekrar
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Şifre Tekrar")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryTextColor)
                                    
                                    SecureField("••••••••", text: $confirmPassword)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Hata mesajı
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Kayıt ol butonu
                        Button(action: signUp) {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Kayıt Ol")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.white)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.textColor)
                    }
                }
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        guard !firstName.isEmpty, !lastName.isEmpty,
              !email.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen tüm alanları doldurun"
            isLoading = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Şifreler eşleşmiyor"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalıdır"
            isLoading = false
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Geçerli bir email adresi girin"
            isLoading = false
            return
        }
        
        let userData: [String: Any] = [
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "isAdmin": false,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "joinDate": Timestamp(),
            "calorieGoal": NSNull(),
            "workoutGoal": NSNull(),
            "weightGoal": NSNull(),
            "personalBests": [:] as [String: Double],
            "progressNotes": [] as [[String: Any]]
        ]
        
        Task {
            do {
                let result = try await FirebaseManager.shared.auth.createUser(withEmail: email, password: password)
                let userId = result.user.uid
                
                try await FirebaseManager.shared.signUp(userData: userData, userId: userId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
