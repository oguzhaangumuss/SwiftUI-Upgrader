import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            HStack {
                Text(exercise.muscleGroups.map { $0.rawValue }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let rating = exercise.averageRating {
                    RatingView(rating: rating)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RatingView: View {
    let rating: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 