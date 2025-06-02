import Foundation

/// Supabase Storage işlemleri için kullanılan servis sınıfı
class SupabaseService {
    static let shared = SupabaseService()
    
    // Supabase proje bilgileri
    //private let projectRef = "vnrffmizzujevpqygtpv"
    private let projectRef = "yqlomstlasmxrulpnlwx"
    private let supabaseRegion = "eu-central-2"
    private let bucketName = "food-images"
    
    // Supabase Storage URL'i
    private var storageEndpoint: String {
        return "https://\(projectRef).supabase.co/storage/v1/object"
    }
    
    // Public URL endpoint
    private var publicEndpoint: String {
        return "https://\(projectRef).supabase.co/storage/v1/s3\(bucketName)"
        // https://yqlomstlasmxrulpnlwx.supabase.co/storage/v1/s3
    }
    
    // Supabase API key - bu public anon key olmalıdır
    //private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZucmZmbWl6enVqZXZwcXlndHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1NDU2MTMsImV4cCI6MjA2MDEyMTYxM30.xGDva1JUzdx7DcamTtD0NWJGvBGy_XR51kFTeb3-bmA"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlxbG9tc3RsYXNteHJ1bHBubHd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4MTMzNTIsImV4cCI6MjA2NDM4OTM1Mn0.SI1K0YqNGZmjNXwEdh6YWKQ3Ey9HbAC8ztez9dhncUM"
    private init() {}
    
    /// Görsel yükleme metodu
    /// - Parameters:
    ///   - imageData: Yüklenecek görsel verisi
    ///   - path: Supabase Storage'daki yol (klasör yapısı)
    ///   - fileName: Dosya adı
    /// - Returns: İndirme URL'i
    func uploadImage(imageData: Data, path: String, fileName: String) async throws -> String {
        // Supabase Storage endpoint'i
        let uploadPath = path.isEmpty ? fileName : "\(path)/\(fileName)"
        let endpoint = "\(storageEndpoint)/\(bucketName)/\(uploadPath)"
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "SupabaseError", code: 1000, 
                          userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL oluşturuldu"])
        }
        
        print("🌐 Supabase Storage endpoint: \(endpoint)")
        
        // API isteği oluştur
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("*", forHTTPHeaderField: "Cache-Control")
        request.setValue("true", forHTTPHeaderField: "x-upsert") // Dosya zaten varsa üzerine yaz
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        print("🖼️ Supabase Storage'a görsel yükleniyor... Dosya adı: \(fileName)")
        
        // API çağrısı yap
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: imageData)
        
        // Response içeriğini yazdır (debug için)
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("📊 Supabase yanıtı: \(responseString)")
        }
        
        // HTTP yanıtını kontrol et
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseError", code: 1001, 
                          userInfo: [NSLocalizedDescriptionKey: "Geçersiz HTTP yanıtı"])
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Supabase Storage Hatası (HTTP \(httpResponse.statusCode))")
            
            // Response header bilgisini yazdır
            print("🔍 Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("\(key): \(value)")
            }
            
            throw NSError(domain: "SupabaseError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP Hata Kodu: \(httpResponse.statusCode)"])
        }
        
        // Başarılı cevap - pubik URL'i oluştur
        let publicURL = "\(publicEndpoint)/\(uploadPath)"
        print("✅ Supabase Storage görsel yükleme başarılı: \(publicURL)")
        
        return publicURL
    }
    
    /// Görsel silme metodu
    /// - Parameters:
    ///   - path: Supabase Storage'daki tam yol
    func deleteImage(at path: String) async throws {
        let endpoint = "\(storageEndpoint)/\(bucketName)/\(path)"
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "SupabaseError", code: 1000, 
                          userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL oluşturuldu"])
        }
        
        // API isteği oluştur
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        print("🗑️ Supabase Storage'dan görsel siliniyor... Yol: \(path)")
        
        // API çağrısı yap
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // HTTP yanıtını kontrol et
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseError", code: 1001, 
                          userInfo: [NSLocalizedDescriptionKey: "Geçersiz HTTP yanıtı"])
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Supabase Storage Silme Hatası (HTTP \(httpResponse.statusCode))")
            throw NSError(domain: "SupabaseError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP Hata Kodu: \(httpResponse.statusCode)"])
        }
        
        print("✅ Supabase Storage görsel silme başarılı")
    }
} 