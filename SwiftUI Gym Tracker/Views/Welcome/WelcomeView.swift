import SwiftUI

struct WelcomeView: View {
    @State private var isShowingSignUp = false
    @State private var isShowingLogin = false
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arka plan resmi
                Image("welcomePage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Gradient overlay - daha yumuşak geçiş
                LinearGradient(
                    gradient: Gradient(colors: [
                        .black.opacity(0.2),
                        .black.opacity(0.5),
                        .black.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo ve başlık
                    VStack(spacing: 24) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, options: .repeat(2), value: isAnimating)
                        
                        Text("UPGRADER")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(y: isAnimating ? 0 : 30)
                    .opacity(isAnimating ? 1 : 0)
                    
                    // Alt başlık
                    Text("Kendinin daha iyi bir versiyonu\ntam burada başlıyor!")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 16)
                        .padding(.bottom, 48)
                        .offset(y: isAnimating ? 0 : 20)
                        .opacity(isAnimating ? 1 : 0)
                    
                    Spacer()
                    
                    // Butonlar
                    VStack(spacing: 16) {
                        Button {
                            isShowingSignUp = true
                        } label: {
                            Text("Kayıt Ol")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56) // Apple'ın önerdiği minimum 44pt
                                .background(AppTheme.primaryColor)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain) // Daha iyi dokunma geri bildirimi
                        .contentShape(Rectangle()) // Dokunma alanını genişlet
                        
                        Button {
                            isShowingLogin = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Zaten bir hesabın var mı?")
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Giriş Yap")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                    .offset(y: isAnimating ? 0 : 20)
                    .opacity(isAnimating ? 1 : 0)
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $isShowingLogin) {
            LoginView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}
