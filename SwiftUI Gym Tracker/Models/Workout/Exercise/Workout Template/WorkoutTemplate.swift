import FirebaseFirestore

struct WorkoutTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var notes: String?
    var exercises: [TemplateExercise]
    let createdBy: String
    let userId: String
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
}

struct WorkoutTemplateGroup: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    var name: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
}
