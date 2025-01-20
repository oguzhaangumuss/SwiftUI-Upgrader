import SwiftUI
import FirebaseFirestore

struct AddToMealView: View {
    @Environment(\.dismiss) var dismiss
    let food: Food
    @State private var portion = ""
    @State private var selectedMealType = MealType.breakfast
    @State private var selectedDate = Date()
    @State private var errorMessage = ""
    @State private var showExistingMeals = false
    @State private var existingMeals: [UserMeal] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Porsiyon")) {
                    TextField("Miktar (gram)", text: $portion)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Öğün Tipi")) {
                    Picker("Öğün", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Tarih")) {
                    DatePicker("Tarih", selection: $selectedDate, displayedComponents: .date)
                }
                
                // Mevcut öğünler
                if !existingMeals.isEmpty {
                    Section(header: Text("Mevcut Öğünler")) {
                        ForEach(existingMeals) { meal in
                            Button {
                                addToExistingMeal(meal)
                            } label: {
                                HStack {
                                    Text(meal.mealType.rawValue)
                                    Spacer()
                                    Text("\(meal.foods.count) yiyecek")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Öğüne Ekle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Ekle") { addNewMeal() }
            )
            .onAppear {
                fetchExistingMeals()
            }
        }
    }
    
    private func fetchExistingMeals() {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        Task {
            do {
                let snapshot = try await FirebaseManager.shared.firestore
                    .collection("userMeals")
                    .whereField("userId", isEqualTo: userId)
                    .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                    .whereField("date", isLessThan: Timestamp(date: endOfDay))
                    .getDocuments()
                
                await MainActor.run {
                    existingMeals = snapshot.documents.compactMap { try? $0.data(as: UserMeal.self) }
                }
            } catch {
                print("Mevcut öğünler getirilemedi: \(error)")
            }
        }
    }
    
    private func addToExistingMeal(_ meal: UserMeal) {
        guard let portionDouble = Double(portion),
              portionDouble > 0 else {
            errorMessage = "Geçerli bir porsiyon miktarı girin"
            return
        }
        
        Task {
            do {
                var updatedFoods = meal.foods
                updatedFoods.append(MealFood(
                    foodId: food.id!,
                    food: food,  // food parametresini ekledik
                    portion: portionDouble
                ))
                
                try await FirebaseManager.shared.firestore
                    .collection("userMeals")
                    .document(meal.id!)
                    .updateData([
                        "foods": updatedFoods.map { [
                            "foodId": $0.foodId,
                            "portion": $0.portion
                        ] }
                    ])
                
                dismiss()
            } catch {
                errorMessage = "Yiyecek eklenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    private func addNewMeal() {
        guard let portionDouble = Double(portion),
              portionDouble > 0 else {
            errorMessage = "Geçerli bir porsiyon miktarı girin"
            return
        }
        
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let totalCalories = food.calories * portionDouble
        
        let mealData: [String: Any] = [
            "userId": userId,
            "mealType": selectedMealType.rawValue,
            "date": Timestamp(date: selectedDate),
            "foods": [[
                "foodId": food.id!,
                "portion": portionDouble
            ]],
            "totalCalories": totalCalories,
            "createdAt": Timestamp()
        ]
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("userMeals")
                    .document()
                    .setData(mealData)
                
                dismiss()
            } catch {
                errorMessage = "Öğün eklenemedi: \(error.localizedDescription)"
            }
        }
    }
} 
