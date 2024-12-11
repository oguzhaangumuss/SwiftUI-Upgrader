import SwiftUI
import FirebaseFirestore

struct AddFoodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var foodsViewModel = FoodsViewModel.shared
    
    @State private var name = ""
    @State private var brand = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Temel Bilgiler")) {
                    TextField("Yiyecek Adı", text: $name)
                    TextField("Marka (Opsiyonel)", text: $brand)
                }
                
                Section(header: Text("Besin Değerleri (100g)")) {
                    TextField("Kalori", text: $calories)
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
            .navigationTitle("Yiyecek Ekle")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") { saveFood() }
                    .disabled(isLoading)
            )
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func saveFood() {
        // Validasyon
        guard !name.isEmpty else {
            errorMessage = "Yiyecek adı boş olamaz"
            return
        }
        
        guard let caloriesInt = Int(calories),
              let proteinDouble = Double(protein),
              let carbsDouble = Double(carbs),
              let fatDouble = Double(fat) else {
            errorMessage = "Lütfen geçerli sayısal değerler girin"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let foodData: [String: Any] = [
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "brand": brand.trimmingCharacters(in: .whitespacesAndNewlines),
                    "calories": caloriesInt,
                    "protein": proteinDouble,
                    "carbs": carbsDouble,
                    "fat": fatDouble,
                    "createdBy": FirebaseManager.shared.auth.currentUser?.uid ?? "",
                    "createdAt": Timestamp(),
                    "updatedAt": Timestamp()
                ]
                
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document()
                    .setData(foodData)
                
                dismiss()
            } catch {
                errorMessage = "Yiyecek eklenirken hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
} 