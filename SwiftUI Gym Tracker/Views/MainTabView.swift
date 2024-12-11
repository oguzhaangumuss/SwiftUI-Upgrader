import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ExercisesView()
                .tabItem {
                    Label("Egzersizler", systemImage: "figure.walk")
                }
            
            WorkoutPlanView()
                .tabItem {
                    Label("Antrenmanlar", systemImage: "dumbbell")
                }
            
            FoodsView()
                .tabItem {
                    Label("Yiyecekler", systemImage: "apple.logo")
                }
            
            MealsView()
                .tabItem {
                    Label("Öğünler", systemImage: "fork.knife")
                }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle")
            }
        }
    }
} 
