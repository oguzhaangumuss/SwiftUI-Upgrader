import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    let user: User
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var age: String
    @State private var height: String
    @State private var weight: String
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var calorieGoal: String = ""
    @State private var workoutGoal: String
    @State private var weightGoal: String = ""
    
    init(user: User) {
           self.user = user
           _firstName = State(initialValue: user.firstName)
           _lastName = State(initialValue: user.lastName)
           _age = State(initialValue: user.age == 0 ? "" : String(user.age ?? 0))
           _height = State(initialValue: user.height == 0 ? "" : String(user.height ?? 0))
           _weight = State(initialValue: user.weight == 0 ? "" : String(user.weight ?? 0))
           _calorieGoal = State(initialValue: user.calorieGoal == 1 ? "" : String(user.calorieGoal ?? 1))
           _workoutGoal = State(initialValue: user.workoutGoal == 1 ? "" : String(user.workoutGoal ?? 1))
           _weightGoal = State(initialValue: user.weightGoal == 1 ? "" : String(user.weightGoal ?? 1))
       }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)
                    TextField("Yaş", text: $age)
                        .keyboardType(.numberPad)
                        
                        
                }
                
                Section(header: Text("Fiziksel Bilgiler")) {
                    TextField("Boy (cm)", text: $height)
                        .placeholder(when: height == "") {
                        }
                        .keyboardType(.decimalPad)
                    TextField("Kilo (kg)", text: $weight)
                        .placeholder(when: weight == "") {
                        }
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Hedefler")) {
                    TextField("Hedef Kalori (kcal)", text: $calorieGoal)
                        .placeholder(when: calorieGoal == "") {
                            
                        }
                        .keyboardType(.decimalPad)
                    TextField("Hedef Kilo (kg)", text: $weightGoal)
                        .placeholder(when: weightGoal == "1") {
                            
                        }
                        .keyboardType(.decimalPad)
                    TextField("Hedef Antrenman (hafta)", text: $workoutGoal)
                        .placeholder(when: workoutGoal == "1") {
                            
                        }
                        .keyboardType(.decimalPad)
                }
                            
                if user.age == 0 || user.height == 0 || user.weight == 0 || calorieGoal == "1" || weightGoal == "1" || workoutGoal == "1    " {
                    Section {
                        Text("Lütfen eksik bilgileri tamamlayınız.")
                            .foregroundColor(.orange)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { updateProfile() }
                    .disabled(isLoading)
            )
        }
    }
    
    private func updateProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = ""
        
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "age": Int(age) ?? 0,
            "height": Double(height) ?? 0.0,
            "weight": Double(weight) ?? 0.0,
            "updatedAt": Timestamp(),
            "calorieGoal": Int(calorieGoal) ?? 1,
            "weightGoal": Int(weightGoal) ?? 1,
            "workoutGoal": Int(workoutGoal) ?? 1
        ]
        
        Task {
            do {
                try await FirebaseManager.shared.updateUser(userId: userId, data: userData)
                dismiss()
            } catch {
                errorMessage = "Profil güncellenirken hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
} 
