import FirebaseFirestore
import Foundation

struct UserExercise: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let exerciseId: String
    var exerciseName: String?
    var sets: Int
    var reps: Int
    var weight: Double
    let date: Timestamp
    let notes: String?
    let duration: Double  // TimeInterval yerine Double kullanıyoruz
    private let _caloriesBurned: Double? // Firebase'den gelen kalori değeri
    let createdAt: Timestamp
    
    // Hesaplanan kalori değeri
    var caloriesBurned: Double? {
        // Önce Firebase'den gelen değeri kontrol et
        if let calories = _caloriesBurned {
            return calories
        }
        
        // Firebase'den gelen değer yoksa hesapla
        let hours = duration / 3600.0 // Süreyi saate çevir (Double olarak bölme işlemi)
        let userWeight = FirebaseManager.shared.currentUser?.weight ?? 70 // Varsayılan ağırlık
        // Saatte yakılan kalori = MET * ağırlık * saat
        return (7.0 * userWeight * hours) // Varsayılan MET değeri 7.0 (orta şiddetli egzersiz)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case exerciseId
        case exerciseName
        case sets
        case reps
        case weight
        case date
        case notes
        case duration
        case _caloriesBurned = "caloriesBurned"
        case createdAt
    }
} 
