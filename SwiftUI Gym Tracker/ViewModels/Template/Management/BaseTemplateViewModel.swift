import SwiftUI
import Combine

/// Şablon yönetimi ViewModel'leri için temel sınıf
class BaseTemplateViewModel: ObservableObject {
    /// Yükleme durumu
    @Published var isLoading = false
    
    /// Hata mesajı
    @Published var errorMessage: String?
    
    /// Veri erişimi için repository
    let repository = TemplateRepository()
    
    /// Otomatik temizlenen Combine abonelikleri
    var cancellables = Set<AnyCancellable>()
    
    /// Standart hata işleme
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            self.errorMessage = appError.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
        print("❌ Hata: \(error.localizedDescription)")
    }
    
    /// UI güncelleme işlemini ana thread'e taşır
    func updateOnMain(_ action: @escaping () -> Void) {
        DispatchQueue.main.async {
            action()
        }
    }
    
    /// İşlemi başlatırken yükleme durumunu günceller
    func startLoading() {
        updateOnMain {
            self.isLoading = true
            self.errorMessage = nil
        }
    }
    
    /// İşlemi tamamlarken yükleme durumunu günceller
    func finishLoading() {
        updateOnMain {
            self.isLoading = false
        }
    }
} 