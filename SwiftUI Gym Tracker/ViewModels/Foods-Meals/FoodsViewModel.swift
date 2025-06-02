import SwiftUI
import FirebaseFirestore

// MARK: - Sort Options
enum SortOption: String, CaseIterable, Identifiable {
    case nameAsc = "İsim (A-Z)"
    case nameDesc = "İsim (Z-A)"
    case caloriesAsc = "Kalori (Artan)"
    case caloriesDesc = "Kalori (Azalan)"
    case proteinAsc = "Protein (Artan)"
    case proteinDesc = "Protein (Azalan)"
    
    var id: String { self.rawValue }
}

class FoodsViewModel: ObservableObject {
    static let shared = FoodsViewModel()
    
    @Published var foods: [Food] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: Food.Category?
    @Published var sortOption: SortOption = .nameAsc
    @Published var searchText = ""
    
    private let db = FirebaseManager.shared.firestore
    private var listener: ListenerRegistration?
    
    private init() {
        setupListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // Kategorilere göre filtrelenmiş yiyecekler
    func filteredFoods(searchText: String) -> [Food] {
        var filtered = foods
        
        // Metne göre filtrele
        if !searchText.isEmpty {
            filtered = filtered.filter { food in
                food.name.localizedCaseInsensitiveContains(searchText) ||
                food.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Kategoriye göre filtrele
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { food in
                food.foodCategory == selectedCategory
            }
        }
        
        return filtered
    }
    
    // Kategoriye göre yiyecekleri grupla
    func groupedFoods(searchText: String) -> [Food.Category: [Food]] {
        let filtered = filteredFoods(searchText: searchText)
        
        var grouped = [Food.Category: [Food]]()
        
        for category in Food.Category.allCases {
            let foodsInCategory = filtered.filter { $0.foodCategory == category }
            if !foodsInCategory.isEmpty {
                grouped[category] = foodsInCategory
            }
        }
        
        return grouped
    }
    
    // Kategorileri getir
    var availableCategories: [Food.Category] {
        var categories = Set<Food.Category>()
        
        for food in foods {
            categories.insert(food.foodCategory)
        }
        
        return Array(categories).sorted { $0.rawValue < $1.rawValue }
    }
    
    func fetchFoods() {
        Task {
            await MainActor.run {
                isLoading = true
                foods = []
            }
            
            do {
                let snapshot = try await db.collection("foods").getDocuments()
                let fetchedFoods = snapshot.documents.compactMap { document -> Food? in
                    try? document.data(as: Food.self)
                }
                
                await MainActor.run {
                    self.foods = fetchedFoods
                    self.isLoading = false
                }
                
            } catch {
                print("Error fetching foods: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func setupListener() {
        isLoading = true
        
        listener = db.collection("foods")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Hata oluştu: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                self.foods = snapshot?.documents.compactMap { document -> Food? in
                    try? document.data(as: Food.self)
                } ?? []
                
                self.isLoading = false
            }
    }
    
    var filteredFoods: [Food] {
        var result = foods
        
        // Kategori filtresi
        if let selectedCategory = selectedCategory {
            result = result.filter { $0.foodCategory == selectedCategory }
        }
        
        // Arama filtresi
        if !searchText.isEmpty {
            result = result.filter { food in
                food.name.lowercased().contains(searchText.lowercased()) ||
                food.brand.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Sıralama
        switch sortOption {
        case .nameAsc:
            result.sort { $0.name < $1.name }
        case .nameDesc:
            result.sort { $0.name > $1.name }
        case .caloriesAsc:
            result.sort { $0.calories < $1.calories }
        case .caloriesDesc:
            result.sort { $0.calories > $1.calories }
        case .proteinAsc:
            result.sort { $0.protein < $1.protein }
        case .proteinDesc:
            result.sort { $0.protein > $1.protein }
        }
        
        return result
    }
    
    // ID'ye göre yemek nesnesi döndüren fonksiyon
    func getFood(by id: String) -> Food? {
        return foods.first(where: { $0.id == id })
    }
    
    func selectCategory(_ category: Food.Category?) {
        selectedCategory = category
    }
} 