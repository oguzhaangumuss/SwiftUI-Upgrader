import SwiftUI

struct AdminTabView: View {
    @State private var showingLogoutAlert = false
    
    var body: some View {
        TabView {
            NavigationView {
                AdminExercisesView()
            }
            .tabItem {
                Label("Egzersizler", systemImage: "dumbbell")
            }
            
            NavigationView {
                AdminFoodsView()
            }
            .tabItem {
                Label("Yiyecekler", systemImage: "fork.knife")
            }
            
            NavigationView {
                AdminUsersView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingLogoutAlert = true
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Kullanıcılar", systemImage: "person.2")
            }
        }
        .alert("Çıkış Yap", isPresented: $showingLogoutAlert) {
            Button("Çıkış Yap", role: .destructive) {
                try? FirebaseManager.shared.auth.signOut()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Çıkış yapmak istediğinizden emin misiniz?")
        }
    }
} 
