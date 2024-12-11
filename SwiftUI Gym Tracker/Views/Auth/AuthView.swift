import SwiftUI

struct AuthView: View {
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo veya uygulama adı
                Text("Welcome To Upgrader")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 50)
                // Giriş formu
                LoginView()
                    .padding(.horizontal)
                
                // Kayıt ol butonu
                Button(action: {
                    isShowingSignUp = true
                }) {
                    Text("Hesabın yok mu? Kayıt ol")
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
}

#Preview {
    AuthView()
} 
