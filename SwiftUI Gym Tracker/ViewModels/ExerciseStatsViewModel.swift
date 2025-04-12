import FirebaseFirestore
import Foundation

class ExerciseStatsViewModel: ObservableObject {
    @Published var currentStats = ExerciseStats()
    @Published var chartData: [CaloriesDataPoint] = []
    @Published var exerciseDistribution: [ExerciseTypeData] = []
    
    @MainActor
    func fetchStats(for period: ExerciseStatsView.StatsPeriod) async {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .weekly:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        }
        
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
                .whereField("date", isLessThan: Timestamp(date: now))
                .getDocuments()
            
            var stats = ExerciseStats()
            var dataPoints: [Date: CaloriesDataPoint] = [:]
            var exerciseStats: [String: Double] = [:]
            
            for document in snapshot.documents {
                guard let workout = try? document.data(as: UserExercise.self) else { continue }
                
                if let calories = workout.caloriesBurned,
                   let exerciseName = workout.exerciseName {
                    stats.totalCalories += calories
                    
                    // Egzersiz bazında istatistik
                    exerciseStats[exerciseName, default: 0] += calories
                }
                
                stats.totalWorkouts += 1
                stats.totalDuration += workout.duration
                
                // Günlük kalori verisi
                let date = workout.date.dateValue()
                let dayStart = calendar.startOfDay(for: date)
                
                var point = dataPoints[dayStart] ?? CaloriesDataPoint(date: dayStart)
                point.calories += workout.caloriesBurned ?? 0
                dataPoints[dayStart] = point
            }
            
            currentStats = stats
            chartData = dataPoints.values.sorted { $0.date < $1.date }
            
            // Egzersiz dağılımı
            exerciseDistribution = exerciseStats.map { name, calories in
                ExerciseTypeData(name: name, calories: calories)
            }.sorted { $0.calories > $1.calories }
            
        } catch {
            print("İstatistikler getirilemedi: \(error)")
        }
    }
}

struct ExerciseStats {
    var totalCalories: Double = 0
    var totalWorkouts: Int = 0
    var totalDuration: Double = 0
}

struct CaloriesDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    var calories: Double = 0
}

struct ExerciseTypeData: Identifiable {
    let id = UUID()
    let name: String
    let calories: Double
} 
