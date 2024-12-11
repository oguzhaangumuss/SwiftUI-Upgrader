import SwiftUI
import FirebaseFirestore

struct EditFoodView: View {
    let food: Food
    @Environment(\.dismiss) var dismiss
    @StateObject private var foodsViewModel = FoodsViewModel.shared
    
    @State private var name: String
    @State private var brand: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(food: Food) {
        self.food = food
        _name = State(initialValue: food.name)
        _brand = State(initialValue: food.brand)
        _calories = State(initialValue: String(Int(food.calories)))
        _protein = State(initialValue: String(food.protein))
        _carbs = State(initialValue: String(food.carbs))
        _fat = State(initialValue: String(food.fat))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Yiyecek Bilgileri")) {
                    TextField("Yiyecek Adı", text: $name)
                    TextField("Marka", text: $brand)
                }
                
                Section(header: Text("Besin Değerleri (100g için)")) {
                    TextField("Kalori (kcal)", text: $calories)
                        .keyboardType(.numberPad)
                    
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    
                    TextField("Karbonhidrat (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    
                    TextField("Yağ (g)", text: $fat)
                        .keyboardType(.decimalPad)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Yiyeceği Düzenle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { updateFood() }
                    .disabled(isLoading)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func updateFood() {
        guard !name.isEmpty else {
            errorMessage = "Yiyecek adı boş olamaz"
            return
        }
        
        guard !brand.isEmpty else {
            errorMessage = "Marka adı boş olamaz"
            return
        }
        
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if foodsViewModel.foods.contains(where: { 
            $0.id != food.id && 
            $0.name.lowercased() == normalizedName && 
            $0.brand.lowercased() == normalizedBrand 
        }) {
            errorMessage = "Bu marka için aynı isimde yiyecek zaten mevcut"
            return
        }
        
        guard let caloriesInt = Int(calories),
              let proteinDouble = Double(protein),
              let carbsDouble = Double(carbs),
              let fatDouble = Double(fat) else {
            errorMessage = "Lütfen geçerli sayısal değerler girin"
            return
        }
        
        guard let foodId = food.id else {
            errorMessage = "Yiyecek ID'si bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let foodData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "brand": brand.trimmingCharacters(in: .whitespacesAndNewlines),
            "calories": caloriesInt,
            "protein": proteinDouble,
            "carbs": carbsDouble,
            "fat": fatDouble,
            "updatedAt": Timestamp()
        ]
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document(foodId)
                    .updateData(foodData)
                dismiss()
            } catch {
                errorMessage = "Yiyecek güncellenirken hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
} 
