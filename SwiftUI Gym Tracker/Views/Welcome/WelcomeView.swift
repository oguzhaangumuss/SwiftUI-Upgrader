//import SwiftUI
//
//struct Welcomeview: View {
//    @State private var Isshowingsignup = False
//    @State private var Isshowinglogin = False
//    
//    var Body: some View {
//        ZStack{
//            // Arka Plan Resmi
//            Image("Welcomepage") // Assets'teki Resmin Adı
//                .Resizable()
//                .Aspectratio(Contentmode: .Fill)
//                .Edgesignoringsafearea(.All)
//                .Overlay(
//                    Lineargradient(
//                        Gradient: Gradient(Colors: [.Black.Opacity(0.7), .Black.Opacity(0.9)]),
//                        Startpoint: .Top,
//                        Endpoint: .Bottom
//                    )
//                )
//            
//            Vstack(Alignment: .Center, Spacing: 20) {
//                // Başlık Bölümü
//                Spacer()
//                Vstack(Alignment: .Center, Spacing: 8) {
//                    Text("Upgrader'a Hoş Geldiniz!")
//                        .Font(.System(Size: 28, Weight: .Bold))
//                        .Foregroundcolor(Apptheme.Textcolor)
//                        .Multilinetextalignment(.Center)
//                    
//                    Text("Kendinin Daha Iyi Bir Versiyonu Tam Burada Başlıyor!")
//                        .Font(.Subheadline)
//                        .Foregroundcolor(Apptheme.Secondarytextcolor)
//                        .Multilinetextalignment(.Center)
//                }
//                .Padding(.Bottom, 42)
//                Spacer()
//                
//                // Butonlar
//                Vstack(Spacing: 12) {
//                    Button {
//                        Isshowingsignup = True
//                    } Label: {
//                        Text("Kayıt Ol")
//                            .Font(.Headline)
//                            .Foregroundcolor(Apptheme.Textcolor)
//                            .Frame(Maxwidth: .Infinity)
//                            .Frame(Height: 45) // Dokunma Alanını Artırdık
//                            .Background(Apptheme.Primarycolor)
//                            .Cornerradius(15)
//                    }
//                    
//                    Hstack(Spacing: 4) {
//                        Text("Zaten Bir Hesabınız Var Mı?")
//                            .Foregroundcolor(Apptheme.Secondarytextcolor)
//                        Button {
//                            Isshowinglogin = True
//                        } Label: {
//                            Text("Giriş Yap")
//                                .Foregroundcolor(Apptheme.Accentcolor)
//                        }
//                    }
//                    .Font(.Subheadline)
//                }
//                .Padding(.Bottom, 40)
//            }
//            .Padding(.Horizontal, 24)
//        }
//        .Sheet(Ispresented: $Isshowingsignup) {
//            Signupview()
//        }
//        .Sheet(Ispresented: $Isshowinglogin) {
//            Loginview()
//        }
//    }
//}
//
//Struct Welcomeview_previews: Previewprovider {
//    Static Var Previews: Some View {
//        Welcomeview()
//    }
//}

// MARK: - 2. deneme
//import SwiftUI
//struct WelcomeView: View {
//    @State private var isShowingSignUp = false
//    @State private var isShowingLogin = false
//    @State private var isAnimating = false
//    
//    var body: some View {
//        ZStack {
//            // Arka plan resmi
//            Image("welcomePage")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .edgesIgnoringSafeArea(.all)
//            
//            // Gradient overlay
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    .black.opacity(0.3),
//                    .black.opacity(0.7),
//                    .black.opacity(0.9)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .edgesIgnoringSafeArea(.all)
//            
//            // İçerik
//            VStack(spacing: 30) {
//                Spacer()
//                
//                // Logo ve Başlık
//                VStack(spacing: 20) {
//                    Image(systemName: "figure.strengthtraining.traditional")
//                        .font(.system(size: 80))
//                        .foregroundColor(.white)
//                        .opacity(isAnimating ? 1 : 0)
//                        .offset(y: isAnimating ? 0 : 20)
//                    
//                    Text("UPGRADER")
//                        .font(.system(size: 40, weight: .bold))
//                        .foregroundColor(.white)
//                        .opacity(isAnimating ? 1 : 0)
//                        .offset(y: isAnimating ? 0 : 20)
//                }
//                
//                // Alt başlık
//                Text("Kendinin daha iyi bir versiyonu\ntam burada başlıyor!")
//                    .font(.title3)
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.white.opacity(0.8))
//                    .padding(.top, 10)
//                    .opacity(isAnimating ? 1 : 0)
//                    .offset(y: isAnimating ? 0 : 20)
//                
//                Spacer()
//                
//                // Butonlar
//                VStack(spacing: 16) {
//                    Button {
//                        isShowingSignUp = true
//                    } label: {
//                        Text("Kayıt Ol")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 56)
//                            .background(AppTheme.primaryColor)
//                            .cornerRadius(16)
//                    }
//                    .opacity(isAnimating ? 1 : 0)
//                    .offset(y: isAnimating ? 0 : 20)
//                    
//                    HStack(spacing: 4) {
//                        Text("Zaten bir hesabın var mı?")
//                            .foregroundColor(.white.opacity(0.7))
//                        Button {
//                            isShowingLogin = true
//                        } label: {
//                            Text("Giriş Yap")
//                                .fontWeight(.semibold)
//                                .foregroundColor(.white)
//                        }
//                    }
//                    .font(.subheadline)
//                    .opacity(isAnimating ? 1 : 0)
//                }
//                .padding(.bottom, 50)
//            }
//            .padding(.horizontal, 24)
//        }
//        .sheet(isPresented: $isShowingSignUp) {
//            SignUpView()
//        }
//        .sheet(isPresented: $isShowingLogin) {
//            LoginView()
//        }
//        .onAppear {
//            withAnimation(.easeOut(duration: 1.0)) {
//                isAnimating = true
//            }
//        }
//    }
//}

// MARK: - 3. Deneme

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
