import SwiftUI
import FirebaseFirestore

class CustomReportViewModel: ObservableObject {
    @Published var caloriesBurned: Double = 0
    @Published var workoutCount: Int = 0
    @Published var weightChange: Double?
    @Published var personalBests: [String: Double] = [:]
    @Published var isLoading = false
    
    @MainActor
    func fetchData(startDate: Date, endDate: Date) async {
        isLoading = true
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            isLoading = false
            return
        }
        
        do {
            // Yakılan kalorileri getir
            let exercisesSnapshot = try await FirebaseManager.shared.firestore
                .collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                .whereField("date", isLessThan: Timestamp(date: endDate))
                .getDocuments()
            
            caloriesBurned = exercisesSnapshot.documents
                .compactMap { try? $0.data(as: UserExercise.self) }
                .compactMap { $0.caloriesBurned }
                .reduce(0, +)
            
            workoutCount = exercisesSnapshot.documents.count
            
            // Kilo değişimini hesapla
            let userDoc = try await FirebaseManager.shared.firestore
                .collection("users")
                .document(userId)
                .getDocument()
            
            if let user = try? userDoc.data(as: User.self) {
                if let notes = user.progressNotes {
                    let relevantNotes = notes
                        .filter { $0.date.dateValue() >= startDate && $0.date.dateValue() <= endDate }
                        .sorted { $0.date.dateValue() < $1.date.dateValue() }
                    
                    if let firstWeight = relevantNotes.first?.weight,
                       let lastWeight = relevantNotes.last?.weight {
                        weightChange = lastWeight - firstWeight
                    }
                }
                
                personalBests = user.personalBests ?? [:]
            }
        } catch {
            print("Veri getirme hatası: \(error)")
        }
        
        isLoading = false
    }
} 