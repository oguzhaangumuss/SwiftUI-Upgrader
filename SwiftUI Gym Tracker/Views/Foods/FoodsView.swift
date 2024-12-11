import SwiftUI
import FirebaseFirestore

struct FoodsView: View {
    @StateObject private var foodsViewModel = FoodsViewModel.shared
    @State private var showingAddFood = false
    @State private var searchText = ""
    
    var filteredFoods: [Food] {
        if searchText.isEmpty {
            return foodsViewModel.foods
        }
        return foodsViewModel.foods.filter { food in
            food.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if foodsViewModel.isLoading {
                    ProgressView()
                } else if filteredFoods.isEmpty {
                    EmptyStateView(
                        image: "fork.knife",
                        message: "Henüz yiyecek bulunmuyor"
                    )
                } else {
                    ForEach(filteredFoods) { food in
                        FoodRow(food: food)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Yiyecek Ara")
            .navigationTitle("Yiyecekler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFood = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFood) {
                AddFoodView()
            }
            .refreshable {
                await foodsViewModel.fetchFoods()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFoods"))) { _ in
            Task {
                await foodsViewModel.fetchFoods()
            }
        }
    }
}

struct FoodRow: View {
    let food: Food
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(food.name)
                    .font(.headline)
                Spacer()
                Text(food.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(Int(food.calories)) kcal", systemImage: "flame")
                Spacer()
                Label("P: \(Int(food.protein))g", systemImage: "p.circle")
                Spacer()
                Label("K: \(Int(food.carbs))g", systemImage: "c.circle")
                Spacer()
                Label("Y: \(Int(food.fat))g", systemImage: "f.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            FoodDetailView(food: food)
        }
    }
} 