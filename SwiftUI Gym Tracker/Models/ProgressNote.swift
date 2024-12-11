import FirebaseFirestore

struct ProgressNote: Identifiable, Codable {
    let id: String
    let userId: String
    let date: Timestamp
    let weight: Double
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case date
        case weight
        case note
    }
} 