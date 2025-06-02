import SwiftUI
import FirebaseFirestore
import UIKit

struct UpdateFoodImagesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = UpdateFoodImagesViewModel()
    
    // Düzenleme modunda belirli bir yiyeceğe odaklanmak için
    var selectedFood: Food?
    
    init(selectedFood: Food? = nil) {
        self.selectedFood = selectedFood
    }
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    // Mevcut görsel göster (eğer düzenleme modundaysa)
                    if let food = selectedFood, let imageUrl = food.imageUrl, !imageUrl.isEmpty {
                        Section("Mevcut Görsel") {
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
                                    Text(food.name)
                                        .font(.headline)
                                    Text("Şu anki görsel")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Yerel görsel listesi
                    Section("Kullanılabilir Görseller") {
                        if viewModel.localImages.isEmpty {
                            Text("Hiç görsel bulunamadı")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.localImages, id: \.name) { image in
                                HStack {
                                    Image(image.name)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        .background(Color(.systemGray6))
                                    
                                    Text(image.name.replacingOccurrences(of: "-", with: " "))
                                    
                                    Spacer()
                                    
                                    if let food = selectedFood {
                                        // Düzenleme modunda - doğrudan seçilen yiyeceğe ata
                                        Button {
                                            viewModel.assignImage(image: image, to: food)
                                        } label: {
                                            Text("Bu görseli kullan")
                                                .foregroundColor(.blue)
                                        }
                                    } else if let matchedFood = viewModel.findMatchingFood(for: image.name) {
                                        // Normal mod - eşleşen yiyeceğe ata
                                        Button {
                                            viewModel.assignImage(image: image, to: matchedFood)
                                        } label: {
                                            Text("Ekle: \(matchedFood.name)")
                                                .foregroundColor(.blue)
                                        }
                                    } else {
                                        Text("Eşleşen yiyecek yok")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Yüklenmiş görsel listesi
                    Section("Yüklenmiş Görseller") {
                        if viewModel.uploadedImages.isEmpty {
                            Text("Henüz yüklenmiş görsel yok")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.uploadedImages) { upload in
                                HStack {
                                    AsyncImage(url: URL(string: upload.imageUrl)) { phase in
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
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading) {
                                        Text(upload.foodName)
                                        Text(upload.imageUrl)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Section {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(selectedFood != nil ? "\(selectedFood!.name) - Görsel Seç" : "Görsel Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.scanLocalImages()
                    } label: {
                        Label("Yenile", systemImage: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadFoods()
                viewModel.scanLocalImages()
                await viewModel.loadUploadedImages()
                
                // Eğer belirli bir yiyecek varsa, o yiyeceği aktif olarak ayarla
                if let food = selectedFood {
                    viewModel.setSelectedFood(food)
                }
            }
        }
    }
}

class UpdateFoodImagesViewModel: ObservableObject {
    @Published var foods: [Food] = []
    @Published var localImages: [LocalImage] = []
    @Published var uploadedImages: [UploadedImage] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var selectedFood: Food?
    
    struct LocalImage {
        let name: String
        let path: String
    }
    
    struct UploadedImage: Identifiable {
        let id = UUID()
        let foodName: String
        let imageUrl: String
        let foodId: String
    }
    
    func loadFoods() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("foods")
                .getDocuments()
            
            let loadedFoods = snapshot.documents.compactMap { doc -> Food? in
                try? doc.data(as: Food.self)
            }
            
            DispatchQueue.main.async {
                self.foods = loadedFoods
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Yiyecekler yüklenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func loadUploadedImages() async {
        do {
            // imageUrl alanı olan yiyecekleri getir
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("foods")
                .whereField("imageUrl", isGreaterThan: "")
                .getDocuments()
            
            let images = snapshot.documents.compactMap { doc -> UploadedImage? in
                guard let food = try? doc.data(as: Food.self),
                      let imageUrl = food.imageUrl,
                      let id = food.id else { return nil }
                
                return UploadedImage(foodName: food.name, imageUrl: imageUrl, foodId: id)
            }
            
            DispatchQueue.main.async {
                self.uploadedImages = images
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Yüklenmiş görseller getirilemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func scanLocalImages() {
        // Assets katalogundaki görselleri dinamik olarak taramaya çalışalım
        var availableImages: [LocalImage] = []
        
        // 1. Temel yiyecek görselleri - yaygın kullanılan görseller
        let commonFoodImages = ["apple", "muz", "somon", "sut-tam-yagli", "tam-bugday-ekmegi", 
                              "tavuk-gogsu", "Yumurta", "ekmek", "peynir", "yumurta", "et", 
                              "balık", "meyve", "sebze", "süt", "yoğurt", "pilav", "makarna"]
        
        // 2. Prefixler ile görselleri tarayalım
        let prefixes = ["food-", "food_", "yiyecek-", "yiyecek_"]
        
        // UIKit tarafından kullanılabilen tüm görsel isimleri
        let allImageNames = UIImage.assetImageNames
        
        // Prefixe göre görselleri filtreyelim
        for prefix in prefixes {
            let filteredNames = allImageNames.filter { $0.hasPrefix(prefix) }
            for name in filteredNames {
                if UIImage(named: name) != nil {
                    availableImages.append(LocalImage(name: name, path: name))
                }
            }
        }
        
        // Yaygın yiyecek isimlerini kontrol edelim
        for name in commonFoodImages {
            if UIImage(named: name) != nil && !availableImages.contains(where: { $0.name == name }) {
                availableImages.append(LocalImage(name: name, path: name))
            }
        }
        
        // Henüz hiç görsel bulunamadıysa, tüm Assets görsellerini tarayalım
        if availableImages.isEmpty {
            for name in allImageNames {
                // welcomePage ve FoodImages gibi arayüz görsellerini hariç tutalım
                if name != "welcomePage" && name != "FoodImages" && UIImage(named: name) != nil {
                    availableImages.append(LocalImage(name: name, path: name))
                }
            }
        }
        
        DispatchQueue.main.async {
            self.localImages = availableImages
        }
    }
    
    func findMatchingFood(for imageName: String) -> Food? {
        // Görsel adından yiyecek adını çıkar
        let plainName = imageName
            .replacingOccurrences(of: ".jpg", with: "")
            .replacingOccurrences(of: ".jpeg", with: "")
            .replacingOccurrences(of: "-", with: " ")
        
        // Yiyecek adında içeren bir yiyecek bul
        return foods.first { food in
            // Ada göre eşleşme kontrolü - basitleştirilmiş versiyon
            let foodName = food.name.lowercased()
            let imageBaseName = plainName.lowercased()
            
            return foodName.contains(imageBaseName) || imageBaseName.contains(foodName)
        }
    }
    
    func assignImage(image: LocalImage, to food: Food) {
        // Görsel yükleme - ana thread üzerinde değişken başlatma
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = ""
        }
        
        Task {
            do {
                guard let foodId = food.id else {
                    throw NSError(domain: "foodId", code: 1, userInfo: [NSLocalizedDescriptionKey: "Yiyecek ID'si bulunamadı"])
                }
                
                // UI Image oluştur
                guard let uiImage = UIImage(named: image.name) else {
                    throw NSError(domain: "image", code: 2, userInfo: [NSLocalizedDescriptionKey: "Görsel yüklenemedi"])
                }
                
                // Görsel verisini sıkıştır
                guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
                    throw NSError(domain: "compression", code: 3, userInfo: [NSLocalizedDescriptionKey: "Görsel sıkıştırılamadı"])
                }
                
                print("📸 Görsel yükleme başlıyor: Yiyecek ID: \(foodId), Görsel adı: \(image.name)")
                
                // Supabase Storage'a yükleme yap (Firebase Manager üzerinden)
                let storageFileName = "\(foodId)_\(UUID().uuidString).jpg"
                print("🔍 Yükleme yolu: \(storageFileName)")
                
                // Supabase'e görseli yükle
                let imageUrl = try await FirebaseManager.shared.uploadImageAsync(imageData: imageData, path: storageFileName)
                print("🔗 Yüklenen görsel URL'i: \(imageUrl)")
                
                // Yiyecek dökümanını güncelle
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document(foodId)
                    .updateData(["imageUrl": imageUrl])
                
                // Ana thread üzerinde UI güncellemelerini yap
                await MainActor.run {
                    // Bildirim gönder - başka ekranlar bunu dinleyebilir
                    NotificationCenter.default.post(
                        name: NSNotification.Name("FoodImageSelected"),
                        object: nil,
                        userInfo: ["foodId": foodId, "imageUrl": imageUrl]
                    )
                    
                    // Başarıyla yüklendi
                    self.uploadedImages.append(
                        UploadedImage(foodName: food.name, imageUrl: imageUrl, foodId: foodId)
                    )
                    self.isLoading = false
                }
            } catch {
                print("❌ Görsel yükleme hatası: \(error)")
                
                // Ana thread üzerinde hata mesajını güncelle
                await MainActor.run {
                    self.errorMessage = "Görsel eklenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func setSelectedFood(_ food: Food) {
        self.selectedFood = food
    }
}

// UIImage için extension ekleyelim - Tüm asset görsellerini bulmak için
extension UIImage {
    // Assets katalogundaki tüm görsel isimlerini döndürür
    static var assetImageNames: [String] {
        var names: [String] = []
        
        // Asset katalog isimlerini tutan isim listeleri
        if let bundleURL = Bundle.main.resourceURL,
           let assetURLs = try? FileManager.default.contentsOfDirectory(at: bundleURL.appendingPathComponent("Assets.car"), 
                                                                        includingPropertiesForKeys: nil) {
            for url in assetURLs {
                let filename = url.deletingPathExtension().lastPathComponent
                if UIImage(named: filename) != nil {
                    names.append(filename)
                }
            }
        }
        
        // Eğer yukarıdaki yöntem çalışmazsa, manuel olarak bilinen görsel isimlerini ekleyelim
        if names.isEmpty {
            // Temel görsel isimleri - birçok projede ortak olan resimler
            names = ["apple", "muz", "somon", "sut-tam-yagli", "tam-bugday-ekmegi", 
                    "tavuk-gogsu", "Yumurta", "ekmek", "peynir", "yumurta"]
        }
        
        return names
    }
} 