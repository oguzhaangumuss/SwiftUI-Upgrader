import SwiftUI
import FirebaseFirestore
import PhotosUI

struct AdminAddFoodView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var brand = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Görsel yükleme için state'ler
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var imageUrl: String?
    @State private var isUploadingImage = false
    @State private var showAssetImagePicker = false
    @State private var tempFood: Food? = nil // Geçici Food nesnesi
    
    var body: some View {
        NavigationView {
            Form {
                // Görsel seçimi
                Section(header: Text("Yiyecek Görseli")) {
                    VStack {
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                        } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(12)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                        .frame(height: 100)
                                        .frame(maxWidth: .infinity)
                                @unknown default:
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .frame(height: 100)
                                .frame(maxWidth: .infinity)
                        }
                        
                        HStack {
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label("Galeriden Seç", systemImage: "photo.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .onChange(of: selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        selectedImageData = data
                                        imageUrl = nil // Galeriden seçim yapıldığında, asset URL'i temizle
                                    }
                                }
                            }
                            
                            Button {
                                // Geçici bir Food nesnesi oluştur
                                createTempFood()
                                showAssetImagePicker = true
                            } label: {
                                Label("Assets'tan Seç", systemImage: "square.grid.2x2")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if isUploadingImage {
                            ProgressView()
                                .padding(.top, 8)
                        }
                    }
                }
                
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
            .navigationTitle("Yeni Yiyecek")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Ekle") { addFood() }
                    .disabled(isLoading || isUploadingImage)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showAssetImagePicker) {
                // UpdateFoodImagesView'a geçici yiyecek nesnesi ile git
                if let food = tempFood {
                    UpdateFoodImagesView(selectedFood: food)
                }
            }
            // Asset görsel seçiminden sonra iletişim kurmak için notification observer ekle
            .onAppear {
                setupNotificationObserver()
            }
            .onDisappear {
                removeNotificationObserver()
            }
        }
    }
    
    // Geçici bir yiyecek nesnesi oluştur (UpdateFoodImagesView için)
    private func createTempFood() {
        let id = UUID().uuidString
        tempFood = Food(
            id: id,
            name: name.isEmpty ? "Yeni Yiyecek" : name,
            brand: brand.isEmpty ? "-" : brand,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            imageUrl: imageUrl,
            createdBy: FirebaseManager.shared.auth.currentUser?.uid ?? "",
            createdAt: Timestamp(),
            updatedAt: Timestamp()
        )
    }
    
    // Bildirim observer'ını kur
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("FoodImageSelected"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let foodId = userInfo["foodId"] as? String,
               let imageUrl = userInfo["imageUrl"] as? String {
                // Eğer seçilen görsel bizim geçici yiyeceğimiz içinse
                if let tempFood = self.tempFood, tempFood.id == foodId {
                    self.imageUrl = imageUrl
                    self.selectedImageData = nil // URL kullanıldığında yerel veriyi temizle
                }
            }
        }
    }
    
    // Observer'ı kaldır
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("FoodImageSelected"),
            object: nil
        )
    }
    
    private func uploadImage() async -> String? {
        guard let imageData = selectedImageData else { return nil }
        
        isUploadingImage = true
        defer { isUploadingImage = false }
        
        do {
            // Firebase Storage'a resmi yükle
            let fileName = "\(UUID().uuidString)_\(name.lowercased().replacingOccurrences(of: " ", with: "_")).jpg"
            let storageRef = "foods/\(fileName)" // "food-images/" yerine "foods/" path'ini kullan

            // Modern, asenkron yöntemi kullan
            return try await FirebaseManager.shared.uploadImageAsync(imageData: imageData, path: storageRef)
        } catch {
            errorMessage = "Görsel yüklenirken hata oluştu: \(error.localizedDescription)"
            print("❌ AdminAddFoodView - Görsel yükleme hatası: \(error)")
            return nil
        }
    }
    
    private func addFood() {
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
            // Eğer görsel varsa önce görseli yükle
            var uploadedImageUrl: String? = nil
            if selectedImageData != nil {
                uploadedImageUrl = await uploadImage()
            }
            
            var foodData: [String: Any] = [
                "name": name,
                "brand": brand.isEmpty ? "-" : brand,
                "calories": caloriesInt,
                "protein": proteinDouble,
                "carbs": carbsDouble,
                "fat": fatDouble,
                "createdBy": FirebaseManager.shared.auth.currentUser?.uid ?? "",
                "createdAt": Timestamp(),
                "updatedAt": Timestamp()
            ]
            
            // Eğer görsel URL'i varsa ekle
            if let imageUrl = uploadedImageUrl {
                foodData["imageUrl"] = imageUrl
            }
            
            do {
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