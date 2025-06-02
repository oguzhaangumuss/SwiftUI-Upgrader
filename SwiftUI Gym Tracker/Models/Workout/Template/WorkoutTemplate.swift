import FirebaseFirestore
import Foundation

/// Antrenman şablonu grup modeli
struct WorkoutTemplateGroup: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    var name: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
}

/// Antrenman şablonu modeli
struct WorkoutTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var notes: String?
    var exercises: [TemplateExercise]
    let createdBy: String
    var userId: String
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var groupId: String?
    
    init(id: String? = nil,
         name: String,
         notes: String? = nil,
         exercises: [TemplateExercise],
         createdBy: String,
         userId: String,
         createdAt: Timestamp,
         updatedAt: Timestamp,
         groupId: String? = nil)
        {
        self.id = id
        self.name = name
        self.notes = notes
        self.exercises = exercises
        self.createdBy = createdBy
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.groupId = groupId
    }
    
    /// Şablonu Firestore formatında [String: Any] sözlüğüne dönüştürür
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "notes": notes as Any,
            "exercises": exercises.map { $0.toDictionary() },
            "createdBy": createdBy,
            "userId": userId,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "groupId": groupId as Any
        ]
    }
}

/// Şablon egzersiz modeli
struct TemplateExercise: Identifiable, Codable, Equatable {
    let id: String
    let exerciseId: String
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double
    var notes: String?
    
    // Equatable protokolü için gerekli
    static func == (lhs: TemplateExercise, rhs: TemplateExercise) -> Bool {
        lhs.id == rhs.id &&
        lhs.exerciseId == rhs.exerciseId &&
        lhs.exerciseName == rhs.exerciseName &&
        lhs.sets == rhs.sets &&
        lhs.reps == rhs.reps &&
        lhs.weight == rhs.weight &&
        lhs.notes == rhs.notes
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "exerciseId": exerciseId,
            "exerciseName": exerciseName,
            "sets": sets,
            "reps": reps,
            "weight": weight as Any,  // Optional olduğu için Any olarak cast ediyoruz
            "notes": notes as Any     // Optional olduğu için Any olarak cast ediyoruz
        ]
    }
}

/// WorkoutTemplateGroup için tip takma adı
typealias TemplateGroup = WorkoutTemplateGroup 