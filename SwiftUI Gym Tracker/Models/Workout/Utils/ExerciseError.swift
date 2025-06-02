import Foundation

/// Egzersiz işlemleri için hata tipleri
enum ExerciseError: LocalizedError {
    case fetchFailed
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed: return "Egzersizler yüklenirken bir hata oluştu"
        case .updateFailed: return "Egzersiz güncellenirken bir hata oluştu"
        case .deleteFailed: return "Egzersiz silinirken bir hata oluştu"
        }
    }
} 