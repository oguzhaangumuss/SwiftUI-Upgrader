import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Logo veya Icon
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryColor)
                        .padding(.top, 40)
                    
                    // Giriş formu
                    VStack(spacing: 24) {
                        // Email alanı
                        VStack(alignment: .leading, spacing: 8) {
                            Text("E-posta")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor)
                            
                            TextField("ornek@email.com", text: $email)
                                .textFieldStyle(.plain)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .foregroundColor(.white)
                                .tint(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                        }
                        
                        // Şifre alanı ve Şifremi Unuttum
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Şifre")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor)
                            
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .tint(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            
                            // Şifremi Unuttum bağlantısı
                            HStack {
                                Spacer()
                                Button {
                                    // Şifremi unuttum işlemi
                                } label: {
                                    Text("Şifremi Unuttum")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.primaryColor)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Hata mesajı
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Giriş butonu
                    Button(action: login) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Giriş Yap")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(AppTheme.primaryColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .disabled(isLoading)
                    
                    Spacer()
                }
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
    
    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen email ve şifrenizi girin"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        print("🔐 Giriş denemesi: \(email)")
        
        Task {
            do {
                let result = try await FirebaseManager.shared.auth.signIn(withEmail: email, password: password)
                print("✅ Giriş başarılı: \(result.user.uid)")
                await FirebaseManager.shared.fetchUserData(userId: result.user.uid)
            } catch {
                print("❌ Giriş hatası: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
} 
