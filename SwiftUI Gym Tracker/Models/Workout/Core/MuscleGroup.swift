import FirebaseFirestore
import Foundation

/// Egzersiz kas grupları için enum
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Göğüs"
    case back = "Sırt"
    case legs = "Bacak"
    case shoulders = "Omuz"
    case arms = "Kol"
    case core = "Karın"
    case cardio = "Kardiyo"
    case fullBody = "Tam Vücut"
}

extension MuscleGroup: Identifiable {
    var id: String { self.rawValue }
    var name: String { self.rawValue }
} 