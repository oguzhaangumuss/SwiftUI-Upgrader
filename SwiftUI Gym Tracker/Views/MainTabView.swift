import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var workoutsViewModel = WorkoutsViewModel.shared
    @StateObject private var mealsViewModel = MealsViewModel.shared
    @StateObject private var foodsViewModel = FoodsViewModel.shared
    
    var body: some View {
        TabView {
            ExercisesView()
                .tabItem {
                    Label("Egzersizler", systemImage: "dumbbell")
                }
            
            WorkoutPlanView()
                .tabItem {
                    Label("Antrenmanlar", systemImage: "calendar")
                }
            
            FoodsView()
                .tabItem {
                    Label("Yiyecekler", systemImage: "apple.logo")
                }
            
            MealsView()
                .tabItem {
                    Label("Öğünler", systemImage: "fork.knife")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
        }
        .environmentObject(workoutsViewModel)
        .environmentObject(mealsViewModel)
        .environmentObject(foodsViewModel)
        
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppSettings())
    }
} 
