import Foundation

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from file: String, withExtension: String = "json") throws -> T {
        guard let url = self.url(forResource: file, withExtension: withExtension) else {
            throw BundleError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

enum BundleError: LocalizedError {
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Dosya bulunamadı"
        }
    }
} 