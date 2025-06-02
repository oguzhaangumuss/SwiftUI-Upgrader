import SwiftUI

struct DailyCaloriesSummary: View {
    let workouts: [UserExercise]
    
    private var totalCaloriesBurned: Double {
        workouts.reduce(0) { sum, workout in
            sum + (workout.caloriesBurned ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Bugün Yakılan")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text("\(Int(totalCaloriesBurned))")
                    .font(.title2)
                    .bold()
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

#Preview {
    DailyCaloriesSummary(workouts: [])
} 