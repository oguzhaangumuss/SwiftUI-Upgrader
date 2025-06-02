import SwiftUI
import FirebaseFirestore
import PhotosUI

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
    
    // Resim seçme ve yükleme için state değişkenleri
    @State private var imageUrl: String?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isImageLoading = false
    
    init(food: Food) {
        self.food = food
        _name = State(initialValue: food.name)
        _brand = State(initialValue: food.brand)
        _calories = State(initialValue: String(Int(food.calories)))
        _protein = State(initialValue: String(food.protein))
        _carbs = State(initialValue: String(food.carbs))
        _fat = State(initialValue: String(food.fat))
        _imageUrl = State(initialValue: food.imageUrl)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Yiyecek Bilgileri")) {
                    TextField("Yiyecek Adı", text: $name)
                    TextField("Marka", text: $brand)
                }
                
                // Resim yükleme bölümü
                Section(header: Text("Yiyecek Görseli")) {
                    VStack {
                        if isImageLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let selectedImageData = selectedImageData, let image = UIImage(data: selectedImageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                        } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(maxHeight: 200)
                        } else {
                            Text("Görsel seçilmedi")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, minHeight: 100)
                        }
                        
                        HStack {
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label("Görsel Seç", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .onChange(of: selectedItem) { newItem in
                                loadTransferable(from: newItem)
                            }
                            
                            if imageUrl != nil || selectedImageData != nil {
                                Button(role: .destructive) {
                                    selectedImageData = nil
                                    imageUrl = nil
                                } label: {
                                    Label("Kaldır", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                            }
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
                    .disabled(isLoading || isImageLoading)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        isImageLoading = true
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                isImageLoading = false
                switch result {
                case .success(let data):
                    if let data = data {
                        self.selectedImageData = data
                        self.imageUrl = nil // URL'yi temizle çünkü yeni resim yükleyeceğiz
                    }
                case .failure(let error):
                    errorMessage = "Görsel yüklenemedi: \(error.localizedDescription)"
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
        
        Task {
            do {
                // Eğer yeni resim seçildiyse önce onu yükle
                var updatedImageUrl = imageUrl
                
                if let imageData = selectedImageData {
                    // Firebase Storage'a yükle
                    let storageFileName = "foods/\(foodId)_\(UUID().uuidString).jpg"
                    updatedImageUrl = try await FirebaseManager.shared.uploadImageAsync(imageData: imageData, path: storageFileName)
                }
                
                let foodData: [String: Any] = [
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "brand": brand.trimmingCharacters(in: .whitespacesAndNewlines),
                    "calories": caloriesInt,
                    "protein": proteinDouble,
                    "carbs": carbsDouble,
                    "fat": fatDouble,
                    "updatedAt": Timestamp(),
                    "imageUrl": updatedImageUrl as Any // nil olabilir o yüzden as Any
                ]
                
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document(foodId)
                    .updateData(foodData)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Yiyecek güncellenirken hata oluştu: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
} 
