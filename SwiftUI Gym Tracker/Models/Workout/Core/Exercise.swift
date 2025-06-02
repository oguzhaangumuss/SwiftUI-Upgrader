import FirebaseFirestore
import Foundation

/// Egzersiz modeli
struct Exercise: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let muscleGroups: [MuscleGroup]
    let createdBy: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    var averageRating: Double?
    var totalRatings: Int
    let metValue: Double?
    
    static var example: Exercise {
        Exercise(
            id: "example",
            name: "Bench Press",
            description: "Klasik göğüs egzersizi",
            muscleGroups: [.chest, .shoulders, .arms],
            createdBy: "admin",
            createdAt: Timestamp(),
            updatedAt: Timestamp(),
            averageRating: 4.5,
            totalRatings: 10,
            metValue: 3.8
        )
    }
}

extension Exercise {
    func calculateCalories(weight: Double, duration: Double) -> Double? {
        guard let metValue = metValue else { return nil }
        
        let hours = duration / 3600.0  // saniyeyi saate çevir (Double olarak bölme)
        return metValue * weight * hours
    }
}
