import SwiftUI
import FirebaseFirestore
import PhotosUI

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
    
    // Resim seçme ve yükleme için state değişkenleri
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isImageLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Temel Bilgiler")) {
                    TextField("Yiyecek Adı", text: $name)
                    TextField("Marka (Opsiyonel)", text: $brand)
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
                            
                            if selectedImageData != nil {
                                Button(role: .destructive) {
                                    selectedImageData = nil
                                } label: {
                                    Label("Kaldır", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
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
                    .disabled(isLoading || isImageLoading)
            )
            .disabled(isLoading)
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
                    }
                case .failure(let error):
                    errorMessage = "Görsel yüklenemedi: \(error.localizedDescription)"
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
                // Foodları kaydetmek için bir döküman ID'si oluştur
                let foodRef = FirebaseManager.shared.firestore.collection("foods").document()
                let foodId = foodRef.documentID
                
                // Eğer resim seçildiyse onu Firebase Storage'a yükle
                var imageUrl: String?
                if let imageData = selectedImageData {
                    let storageFileName = "foods/\(foodId)_\(UUID().uuidString).jpg"
                    imageUrl = try await FirebaseManager.shared.uploadImageAsync(imageData: imageData, path: storageFileName)
                }
                
                // Yiyecek verisini hazırla
                var foodData: [String: Any] = [
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
                
                // Eğer resim URL'i varsa ekle
                if let imageUrl = imageUrl {
                    foodData["imageUrl"] = imageUrl
                }
                
                // Yiyeceği Firestore'a kaydet
                try await foodRef.setData(foodData)
                
                // İşlem başarılı olduğunda ekranı kapat
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Yiyecek eklenirken hata oluştu: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
} 