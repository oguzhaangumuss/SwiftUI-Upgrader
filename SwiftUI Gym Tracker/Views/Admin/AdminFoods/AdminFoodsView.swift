import SwiftUI
import FirebaseFirestore

struct AdminFoodsView: View {
    @StateObject private var viewModel = AdminFoodsViewModel()
    @State private var showingAddFood = false
    @State private var searchText = ""
    
    var filteredFoods: [Food] {
        if searchText.isEmpty {
            return viewModel.foods
        }
        return viewModel.foods.filter { food in
            food.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredFoods) { food in
                NavigationLink {
                    AdminFoodDetailView(food: food)
                } label: {
                    VStack(alignment: .leading) {
                        Text(food.name)
                            .font(.headline)
                        HStack {
                            Text("\(Int(food.calories)) kcal")
                            Text("•")
                            Text("P: \(Int(food.protein))g")
                            Text("•")
                            Text("K: \(Int(food.carbs))g")
                            Text("•")
                            Text("Y: \(Int(food.fat))g")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteFoods(at: indexSet)
                }
            }
        }
        .navigationTitle("Yiyecek Yönetimi")
        .searchable(text: $searchText, prompt: "Yiyecek Ara")
        .toolbar {
            Button {
                showingAddFood = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddFood) {
            AdminAddFoodView()
        }
        .refreshable {
            await viewModel.fetchFoods()
        }
    }
}

class AdminFoodsViewModel: ObservableObject {
    @Published var foods: [Food] = []
    
    init() {
        Task {
            await fetchFoods()
        }
    }
    
    @MainActor
    func fetchFoods() async {
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("foods")
                .getDocuments()
            
            foods = snapshot.documents.compactMap { try? $0.data(as: Food.self) }
        } catch {
            print("Yiyecekler getirilemedi: \(error)")
        }
    }
    
    @MainActor
    func deleteFoods(at indexSet: IndexSet) async {
        for index in indexSet {
            let food = foods[index]
            
            guard let foodId = food.id else {
                print("Yiyecek ID'si bulunamadı")
                continue
            }
            
            do {
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document(foodId)
                    .delete()
                
                foods.remove(at: index)
            } catch {
                print("Yiyecek silinemedi: \(error)")
            }
        }
    }
} 
