import Foundation

/// Kullanıcının belirli bir egzersiz için önceki en iyi performansını temsil eder
struct PreviousBest {
    let weight: Double
    let reps: Int
    let date: Date
} 