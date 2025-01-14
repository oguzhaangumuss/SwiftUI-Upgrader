import Foundation
import FirebaseFirestore

struct PreviousBest: Codable, Equatable {
    let weight: Double
    let reps: Int
    let date: Date
    
    // Equatable protokolü için
    static func == (lhs: PreviousBest, rhs: PreviousBest) -> Bool {
        lhs.weight == rhs.weight &&
        lhs.reps == rhs.reps &&
        lhs.date == rhs.date
    }
} 