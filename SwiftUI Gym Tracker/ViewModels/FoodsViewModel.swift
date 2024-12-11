import SwiftUI
import FirebaseFirestore

class FoodsViewModel: ObservableObject {
    static let shared = FoodsViewModel()
    
    @Published var foods: [Food] = []
    @Published var isLoading = false
    
    private let db = FirebaseManager.shared.firestore
    private var listener: ListenerRegistration?
    
    private init() {
        setupListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    @MainActor
    func fetchFoods() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("foods")
                .order(by: "name")
                .getDocuments()
            
            foods = snapshot.documents.compactMap { try? $0.data(as: Food.self) }
        } catch {
            print("Yiyecekler getirilemedi: \(error)")
        }
        
        isLoading = false
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
    
    func getFood(by id: String) -> Food? {
        return foods.first { $0.id == id }
    }
} 