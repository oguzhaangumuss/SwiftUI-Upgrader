import Foundation

/// Uygulama genelinde kullanılan standart hata tipleri
enum AppError: Error {
    case authError
    case networkError
    case databaseError(String)
    case validationError(String)
    case notFoundError
    
    var localizedDescription: String {
        switch self {
        case .authError:
            return "Kullanıcı oturumu bulunamadı"
        case .networkError:
            return "Ağ hatası oluştu"
        case .databaseError(let message):
            return "Veritabanı hatası: \(message)"
        case .validationError(let message):
            return message
        case .notFoundError:
            return "Aradığınız öğe bulunamadı"
        }
    }
} 