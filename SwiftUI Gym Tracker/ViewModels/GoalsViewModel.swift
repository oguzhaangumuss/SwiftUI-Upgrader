import SwiftUI
import FirebaseFirestore

class GoalsViewModel: ObservableObject {
    // MARK: - Nested Types
    struct Progress {
        var calorieProgress: GoalProgress?
        var workoutProgress: GoalProgress?
        var weightProgress: GoalProgress?
    }
    
    struct GoalProgress {
        let current: Double
        let target: Double
    }
    
    // MARK: - Published Properties
    @Published var caloriesBurned: Double = 0
    @Published var workouts: Int = 0
    @Published var weight: Double = 0
    
    @Published var calorieGoal: Double?
    @Published var workoutGoal: Double?
    @Published var weightGoal: Double?
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Haftalık antrenman verilerini çekmek için yeni bir fonksiyon
    @MainActor
    func fetchWeeklyWorkoutData() async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let today = Date()
        // Haftanın başlangıç tarihini al (Pazartesi)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        // Haftanın bitiş tarihini al (Pazar)
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? today
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("workoutHistory")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: weekStart))
                .whereField("date", isLessThan: Timestamp(date: weekEnd))
                .getDocuments()
            
            var totalCalories: Double = 0
            var workoutCount: Int = 0
            
            for document in snapshot.documents {
                if let workout = try? document.data(as: WorkoutHistory.self) {
                    totalCalories += workout.caloriesBurned ?? 0
                    workoutCount += 1  // Her workout dökümanı bir antrenmanı temsil eder
                }
            }
            
            // Ana thread'de UI güncellemesi
            await MainActor.run {
                self.caloriesBurned = totalCalories
                self.workouts = workoutCount
                self.isLoading = false
            }
            
            print("📊 Haftalık İstatistikler:")
            print("   Yakılan Kalori: \(totalCalories)")
            print("   Antrenman Sayısı: \(workoutCount)")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Antrenman verileri alınamadı"
                self.isLoading = false
            }
            print("❌ Antrenman verileri alınamadı: \(error)")
        }
    }
    
    // Hedefleri çekmek için mevcut fonksiyon
    func fetchGoals() {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isLoading = true
        
        Task {
            do {
                let doc = try await FirebaseManager.shared.firestore
                    .collection("users")
                    .document(userId)
                    .getDocument()
                
                if let user = try? doc.data(as: User.self) {
                    await MainActor.run {
                        
                        self.calorieGoal = Double(user.calorieGoal ?? 1)
                        self.workoutGoal = Double(user.workoutGoal ?? 1)
                        self.weightGoal = user.weightGoal
                        self.weight = user.weight ?? 1
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Hedefler yüklenemedi"
                    self.isLoading = false
                }
            }
        }
    }
    
    func editCalorieGoal() {
        // Kalori hedefi düzenleme işlemi
    }
    
    func editWorkoutGoal() {
        // Antrenman hedefi düzenleme işlemi
    }
    
    func editWeightGoal() {
        // Kilo hedefi düzenleme işlemi
    }
    
    var progress: Progress {
        Progress(
            calorieProgress: calorieGoal.map { GoalProgress(current: caloriesBurned, target: $0) },
            workoutProgress: workoutGoal.map { GoalProgress(current: Double(workouts), target: $0) },
            weightProgress: weightGoal.map { GoalProgress(current: weight, target: $0) }
        )
    }
    
    @MainActor
    func saveGoals(calorieGoal: Int?, workoutGoal: Int?, weightGoal: Double?) async {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        isLoading = true
        
        var updateData: [String: Any] = [:]
        
        if let calorieGoal = calorieGoal {
            updateData["calorieGoal"] = calorieGoal
        }
        if let workoutGoal = workoutGoal {
            updateData["workoutGoal"] = workoutGoal
        }
        if let weightGoal = weightGoal {
            updateData["weightGoal"] = weightGoal
        }
        
        do {
            try await FirebaseManager.shared.firestore
                .collection("users")
                .document(userId)
                .updateData(updateData)
            
            await fetchGoals() // Hedefleri yeniden yükle
        } catch {
            errorMessage = "Hedefler kaydedilemedi"
        }
        
        isLoading = false
    }
    
    
}
