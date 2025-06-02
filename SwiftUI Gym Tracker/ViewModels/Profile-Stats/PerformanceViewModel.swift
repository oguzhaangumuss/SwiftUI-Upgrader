import SwiftUI
import FirebaseFirestore

class PerformanceViewModel: ObservableObject {
    @Published var personalBests: [String: Double]?
    @Published var weightHistory: [WeightDataPoint] = []
    @Published var progressNotes: [User.ProgressNote]?
    
    struct WeightDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
    }
    
    init() {
        Task {
            await fetchData()
        }
    }
    
    @MainActor
    func fetchData() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let userDoc = try await FirebaseManager.shared.firestore
                .collection("users")
                .document(userId)
                .getDocument()
            
            if let user = try? userDoc.data(as: User.self) {
                self.personalBests = user.personalBests
                self.progressNotes = user.progressNotes
                
                // Kilo geçmişini oluştur
                if let notes = user.progressNotes {
                    self.weightHistory = notes.map { note in
                        WeightDataPoint(date: note.date.dateValue(), weight: note.weight)
                    }.sorted { $0.date < $1.date }
                } else {
                    self.weightHistory = []
                }
            }
        } catch {
            print("Veri getirme hatası: \(error)")
        }
    }
} 