import SwiftUI
import FirebaseFirestore

struct AdminEditFoodView: View {
    let food: Food
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showImagePicker = false
    
    init(food: Food) {
        self.food = food
        _name = State(initialValue: food.name)
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
                }
                
                Section(header: Text("Yiyecek Görseli")) {
                    if let imageUrl = food.imageUrl, !imageUrl.isEmpty {
                        HStack {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "photo")
                                @unknown default:
                                    Image(systemName: "photo")
                                }
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("Mevcut Görsel")
                                Text(imageUrl)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("Henüz görsel eklenmemiş")
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo")
                            Text("Görsel Seç veya Değiştir")
                        }
                    }
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
            .sheet(isPresented: $showImagePicker) {
                UpdateFoodImagesView(selectedFood: food)
            }
        }
    }
    
    private func updateFood() {
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
        
        let foodData: [String: Any] = [
            "name": name,
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
                    .document(food.id!)
                    .updateData(foodData)
                dismiss()
            } catch {
                errorMessage = "Yiyecek güncellenirken hata oluştu: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
} 
