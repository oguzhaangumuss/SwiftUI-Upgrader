import SwiftUI
import Charts

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Profil Başlığı
                ProfileHeaderView(user: viewModel.user)
                    .padding(.horizontal)
                
                // 2. Kalori Özeti
                VStack(spacing: 8) {
                    Text("Günlük Kalori Özeti")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CalorieChartView(
                        consumed: viewModel.todaysStats.consumedCalories,
                        burned: viewModel.todaysStats.burnedCalories
                    )
                }
                .padding(.horizontal)
                
                // 3. Günlük İstatistikler
                VStack(spacing: 8) {
                    Text("Günlük İstatistikler")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    QuickStatsView(stats: viewModel.todaysStats)
                }
                .padding(.horizontal)
                
                // 4. Ana Menü Butonları
                NavigationButtonsView()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Profil")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .onAppear {
            Task {
                await viewModel.fetchUserData()
                await viewModel.fetchTodaysStats()
            }
        }
        .refreshable {
            Task {
                await viewModel.fetchUserData()
                await viewModel.fetchTodaysStats()
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
    }
} 
