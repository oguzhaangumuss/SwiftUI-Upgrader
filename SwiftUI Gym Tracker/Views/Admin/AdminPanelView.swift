import SwiftUI
import FirebaseFirestore

struct AdminPanelView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var showingExerciseSeeder = false
    @State private var showingFoodSeeder = false
    
    var body: some View {
        List {
            Section(header: Text("İstatistikler")) {
                HStack {
                    Text("Toplam Kullanıcı")
                    Spacer()
                    Text("\(viewModel.users.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Toplam Egzersiz")
                    Spacer()
                    Text("\(viewModel.exerciseCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Toplam Yiyecek")
                    Spacer()
                    Text("\(viewModel.foodCount)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Veri Yönetimi")) {
                Button {
                    showingExerciseSeeder = true
                } label: {
                    Label("Egzersiz Yükleyici", systemImage: "square.and.arrow.down.fill")
                }
                
                Button {
                    showingFoodSeeder = true
                } label: {
                    Label("Besin Yükleyici", systemImage: "square.and.arrow.down.fill")
                }
            }
        }
        .navigationTitle("Admin Paneli")
        .refreshable {
            await viewModel.fetchData()
        }
        .sheet(isPresented: $showingExerciseSeeder) {
            AdminExerciseSeederView()
        }
        .sheet(isPresented: $showingFoodSeeder) {
            AdminFoodSeederView()
        }
    }
}

// Admin paneli için ViewModel
class AdminViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var exerciseCount = 0
    @Published var foodCount = 0
    
    init() {
        Task {
            await fetchData()
        }
    }
    
    @MainActor
    func fetchData() async {
        do {
            // Kullanıcıları getir
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("users")
                .getDocuments()
            
            users = snapshot.documents.compactMap { doc -> User? in
                let data = doc.data()
                return User(
                    id: doc.documentID,
                    email: data["email"] as? String ?? "",
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    age: data["age"] as? Int ?? 0,
                    height: data["height"] as? Double ?? 0.0,
                    weight: data["weight"] as? Double ?? 0.0,
                    isAdmin: data["isAdmin"] as? Bool ?? false,
                    createdAt: data["createdAt"] as? Timestamp,
                    updatedAt: data["updatedAt"] as? Timestamp,
                    calorieGoal: data["calorieGoal"] as? Int,
                    workoutGoal: data["workoutGoal"] as? Int,
                    weightGoal: data["weightGoal"] as? Double,
                    initialWeight: data["initialWeight"] as? Double,
                    joinDate: data["joinDate"] as? Timestamp ?? Timestamp(),
                    personalBests: data["personalBests"] as? [String: Double] ?? [:],
                    progressNotes: (data["progressNotes"] as? [[String: Any]])?.compactMap { noteData in
                        guard let id = noteData["id"] as? String,
                              let date = noteData["date"] as? Timestamp,
                              let weight = noteData["weight"] as? Double else {
                            return nil
                        }
                        return User.ProgressNote(
                            id: id,
                            date: date,
                            weight: weight,
                            note: noteData["note"] as? String
                        )
                    } ?? []
                )
            }
            
            // İstatistikleri getir
            let exercisesSnapshot = try await FirebaseManager.shared.firestore
                .collection("exercises")
                .count
                .getAggregation(source: .server)
            exerciseCount = Int(truncating: exercisesSnapshot.count)
            
            let foodsSnapshot = try await FirebaseManager.shared.firestore
                .collection("foods")
                .count
                .getAggregation(source: .server)
            foodCount = Int(truncating: foodsSnapshot.count)
            
        } catch {
            print("Veri getirme hatası: \(error)")
        }
    }
} 