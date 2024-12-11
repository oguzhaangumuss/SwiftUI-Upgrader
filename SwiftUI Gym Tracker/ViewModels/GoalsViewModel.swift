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
    @Published var currentCalories: Double = 0
    @Published var currentWorkouts: Double = 0
    @Published var currentWeight: Double = 0
    
    @Published var calorieGoal: Double?
    @Published var workoutGoal: Double?
    @Published var weightGoal: Double?
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // MARK: - Initialization
    init() {
        fetchGoals()
    }
    
    // MARK: - Methods
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
                        self.calorieGoal = Double(user.calorieGoal ?? 0)
                        self.workoutGoal = Double(user.workoutGoal ?? 0)
                        self.weightGoal = user.weightGoal
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
            calorieProgress: calorieGoal.map { GoalProgress(current: currentCalories, target: $0) },
            workoutProgress: workoutGoal.map { GoalProgress(current: currentWorkouts, target: $0) },
            weightProgress: weightGoal.map { GoalProgress(current: currentWeight, target: $0) }
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