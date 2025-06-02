import SwiftUI
import FirebaseFirestore

// Chat message model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let isUserMessage: Bool
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

class AIAssistantViewModel: ObservableObject {
    // MARK: - Properties
    static let shared = AIAssistantViewModel()
    
    @Published var messages: [ChatMessage] = []
    @Published var query: String = ""
    @Published var isLoading: Bool = false
    @Published var isProcessing: Bool = false
    @Published var suggestedQueries: [String] = [
        "Bu hafta ne kadar kalori yakmalıyım?",
        "Kollarımı geliştirmek için hangi egzersizleri yapmalıyım?",
        "Hangi besinler protein açısından zengindir?",
        "Cardio egzersizlerini ne sıklıkta yapmalıyım?"
    ]
    
    // Conversation history for context
    private var conversationHistory: [[String: Any]] = []
    
    // MARK: - Initialization
    private init() {
        // Hoşgeldin mesajı ekleyelim
        addAIResponse("Merhaba! Ben senin fitness asistanınım. Antrenman, beslenme veya sağlıkla ilgili sorularını yanıtlamak için buradayım. Nasıl yardımcı olabilirim?")
    }
    
    // MARK: - Public Methods
    
    // Send a query to Gemini and get a response
    func askGemini() {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userQuery = query
        query = ""
        addUserMessage(userQuery)
    }
    
    // Clear chat messages
    func clearChat() {
        messages.removeAll()
        conversationHistory.removeAll()
        addAIResponse("Merhaba! Ben senin fitness asistanınım. Antrenman, beslenme veya sağlıkla ilgili sorularını yanıtlamak için buradayım. Nasıl yardımcı olabilirim?")
    }
    
    // Add a user message to the chat
    func addUserMessage(_ content: String) {
        isProcessing = true
        
        let message = ChatMessage(
            content: content,
            timestamp: Date(),
            isUserMessage: true
        )
        
        // Add to conversation history for context
        conversationHistory.append([
            "role": "user",
            "parts": [
                ["text": content]
            ]
        ])
        
        messages.append(message)
        
        // Get response from Gemini API
        Task {
            // Kullanıcı verilerini toplayalım
            let userData = await collectUserData()
            
            // Sistem talimatını oluşturalım
            let systemInstruction = """
            Sen bir fitness asistanısın. Kullanıcının fitness hedeflerine ulaşmasına yardımcı oluyorsun.
            
            KULLANICI VERİLERİ:
            \(userData)
            
            Bu bilgileri kullanarak, kullanıcıya kişiselleştirilmiş tavsiyeler ver. Antrenman geçmişi, diyet alışkanlıkları ve hedeflerine dayanarak tavsiyelerde bulun.
            Bilmediğin sorulara "bilmiyorum" diyebilirsin. Yalnızca fitness, sağlık ve beslenme konularında yardımcı ol.
            """
            
            do {
                // Convert conversation history to the format expected by Gemini
                let response = try await GeminiService.shared.askGeminiWithContext(
                    systemInstruction: systemInstruction,
                    conversationHistory: conversationHistory,
                    query: content
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.addAIResponse(response)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.addAIResponse("Üzgünüm, yanıt alırken bir hata oluştu. Lütfen tekrar deneyin.")
                    print("Gemini API error: \(error)")
                }
            }
        }
    }
    
    // Add an AI response to the chat
    private func addAIResponse(_ content: String) {
        let message = ChatMessage(
            content: content,
            timestamp: Date(),
            isUserMessage: false
        )
        
        // Add to conversation history for context
        conversationHistory.append([
            "role": "assistant",
            "parts": [
                ["text": content]
            ]
        ])
        
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }
    
    // Collect user data from the app to provide context
    private func collectUserData() async -> String {
        var userData = "Kullanıcı Profili ve Verileri:\n"
        
        // Get current user data
        if let user = FirebaseManager.shared.currentUser {
            userData += "- İsim: \(user.firstName) \(user.lastName)\n"
            if let weight = user.weight {
                userData += "- Mevcut Kilo: \(String(format: "%.1f", weight)) kg\n"
            }
            if let height = user.height {
                userData += "- Boy: \(String(format: "%.1f", height)) cm\n"
            }
            if let age = user.age {
                userData += "- Yaş: \(age)\n"
            }
            if let calorieGoal = user.calorieGoal {
                userData += "- Günlük Kalori Hedefi: \(calorieGoal) kcal\n"
            }
            if let weightGoal = user.weightGoal {
                userData += "- Kilo Hedefi: \(String(format: "%.1f", weightGoal)) kg\n"
            }
            if let initialWeight = user.initialWeight {
                userData += "- Başlangıç Kilosu: \(String(format: "%.1f", initialWeight)) kg\n"
                userData += "- Kilo Değişimi: \(user.weightChangeText)\n"
            }
        }
        
        // Fetch recent workouts
        do {
            guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { 
                return userData 
            }
            
            // Get last 5 workouts
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("userExercises")
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            if !snapshot.documents.isEmpty {
                userData += "\nSon Antrenmanlar:\n"
                
                var exerciseData: [String: (count: Int, lastWeight: Double)] = [:]
                
                for doc in snapshot.documents {
                    let data = doc.data()
                    
                    if let exerciseName = data["exerciseName"] as? String,
                       let weight = data["weight"] as? Double,
                       let reps = data["reps"] as? Int,
                       let sets = data["sets"] as? Int,
                       let date = data["date"] as? Timestamp {
                        
                        // Track exercise frequency and latest weight
                        if let existing = exerciseData[exerciseName] {
                            exerciseData[exerciseName] = (existing.count + 1, weight)
                        } else {
                            exerciseData[exerciseName] = (1, weight)
                        }
                    }
                }
                
                // Add exercise summary
                for (exercise, data) in exerciseData {
                    userData += "- \(exercise): \(data.count) kez çalışıldı, son ağırlık: \(String(format: "%.1f", data.lastWeight)) kg\n"
                }
            }
            
            // Get recent meals
            let mealSnapshot = try await FirebaseManager.shared.firestore
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            if !mealSnapshot.documents.isEmpty {
                userData += "\nSon Yemekler:\n"
                var foodFrequency: [String: Int] = [:]
                
                for doc in mealSnapshot.documents {
                    let data = doc.data()
                    
                    if let foods = data["foods"] as? [[String: Any]] {
                        for food in foods {
                            if let foodData = food["food"] as? [String: Any],
                               let foodName = foodData["name"] as? String {
                                foodFrequency[foodName] = (foodFrequency[foodName] ?? 0) + 1
                            }
                        }
                    }
                }
                
                // Add top 5 foods
                let topFoods = foodFrequency.sorted { $0.value > $1.value }.prefix(5)
                for (food, count) in topFoods {
                    userData += "- \(food): \(count) kez tüketildi\n"
                }
            }
            
        } catch {
            print("❌ Kullanıcı verileri alınamadı: \(error.localizedDescription)")
        }
        
        return userData
    }
} 