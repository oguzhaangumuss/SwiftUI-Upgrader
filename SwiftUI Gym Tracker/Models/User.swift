import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    let firstName: String
    let lastName: String
    let age: Int
    let height: Double
    var weight: Double
    var isAdmin: Bool
    let createdAt: Timestamp?
    let updatedAt: Timestamp?
    var calorieGoal: Int?
    var workoutGoal: Int?
    var weightGoal: Double?
    var initialWeight: Double?
    let joinDate: Timestamp?
    var personalBests: [String: Double]?
    var progressNotes: [ProgressNote]?
    
    struct ProgressNote: Codable {
        let id: String
        let date: Timestamp
        let weight: Double
        let note: String?
    }
    
    init(id: String? = nil,
         email: String,
         firstName: String,
         lastName: String,
         age: Int,
         height: Double,
         weight: Double,
         isAdmin: Bool,
         createdAt: Timestamp? = nil,
         updatedAt: Timestamp? = nil,
         calorieGoal: Int? = nil,
         workoutGoal: Int? = nil,
         weightGoal: Double? = nil,
         initialWeight: Double? = nil,
         joinDate: Timestamp? = nil,
         personalBests: [String: Double]? = nil,
         progressNotes: [ProgressNote]? = nil) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.height = height
        self.weight = weight
        self.isAdmin = isAdmin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.calorieGoal = calorieGoal
        self.workoutGoal = workoutGoal
        self.weightGoal = weightGoal
        self.initialWeight = initialWeight
        self.joinDate = joinDate
        self.personalBests = personalBests
        self.progressNotes = progressNotes
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var weightChange: Double {
        guard let initialWeight = initialWeight else { return 0 }
        return weight - initialWeight
    }
    
    var weightChangeText: String {
        guard let initialWeight = initialWeight else { return "Başlangıç kilosu girilmemiş" }
        let change = abs(weight - initialWeight)
        if weight > initialWeight {
            return "+\(String(format: "%.1f", change)) kg"
        } else if weight < initialWeight {
            return "-\(String(format: "%.1f", change)) kg"
        }
        return "Değişim yok"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case age
        case height
        case weight
        case isAdmin
        case createdAt
        case updatedAt
        case calorieGoal
        case workoutGoal
        case weightGoal
        case initialWeight
        case joinDate
        case personalBests
        case progressNotes
    }
} 
