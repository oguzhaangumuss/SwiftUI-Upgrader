import SwiftUI
import FirebaseFirestore

class WorkoutHistoryViewModel: ObservableObject {
    @Published var workoutDates: Set<Date> = []
    @Published var selectedDate: Date?
    @Published var dailyWorkouts: [WorkoutHistory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = FirebaseManager.shared.firestore
    
    @MainActor
    func fetchWorkoutDates() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isLoading = true
        
        do {
            let snapshot = try await db.collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            // Antrenman tarihlerini topla
            let dates = snapshot.documents.compactMap { doc -> Date? in
                if let timestamp = doc.data()["date"] as? Timestamp {
                    return Calendar.current.startOfDay(for: timestamp.dateValue())
                }
                return nil
            }
            
            workoutDates = Set(dates)
        } catch {
            errorMessage = "Antrenman tarihleri yüklenemedi"
            print("❌ Tarih yükleme hatası: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchDailyWorkouts(for date: Date) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isLoading = true
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        do {
            let snapshot = try await db.collection("workoutHistory")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            
            print("📊 Bulunan antrenman sayısı: \(snapshot.documents.count)")
            
            dailyWorkouts = try snapshot.documents.map { document in
                try document.data(as: WorkoutHistory.self)
            }
            
        } catch {
            print("❌ Antrenman geçmişi yüklenirken hata: \(error)")
        }
        
        isLoading = false
    }
} 