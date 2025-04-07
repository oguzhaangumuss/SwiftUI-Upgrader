import Foundation
import SwiftUI

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = APIKeys.geminiAPIKey
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    private init() {}
    
    func askGemini(query: String) async throws -> String {
        // API anahtarı kontrolü
        if apiKey.isEmpty {
            print("❌ API anahtarı tanımlanmamış")
            return "API anahtarı tanımlanmamış. Lütfen Config/APIKeys.swift dosyasında apiKey değişkenini güncelleyin."
        }
        
        // Gemini API'si zaten HTTPS kullanıyor
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        print("🤖 Gemini API çağrısı yapılıyor: \(url)")
        
        // Basic prompt without context - v1beta formatına uygun olarak
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": query]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 800
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Geçersiz yanıt: HTTP yanıtı alınamadı")
                throw URLError(.badServerResponse)
            }
            
            // Yanıtı işle
            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                print("📡 Gemini API yanıt kodu: \(httpResponse.statusCode)")
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    // Debug çıktısı
                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject ?? [:], options: [.prettyPrinted]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("✅ API Yanıtı: \(jsonString)")
                    }
                    
                    // Yanıt formatı v1beta: candidates > content > parts > text
                    if let candidates = jsonObject?["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        return text
                    } else {
                        print("❌ Yanıt formatı beklenen gibi değil")
                        return "AI yanıtı alınamadı. Lütfen daha sonra tekrar deneyin."
                    }
                } catch {
                    print("❌ JSON ayrıştırma hatası: \(error)")
                    return "Yanıt ayrıştırılırken hata oluştu: \(error.localizedDescription)"
                }
            } else {
                // Hata mesajını yazdıralım
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ API Hata Yanıtı: \(errorString)")
                }
                throw URLError(.badServerResponse)
            }
            
        } catch {
            print("❌ API çağrısı sırasında hata: \(error.localizedDescription)")
            
            // Daha detaylı hata mesajı oluştur
            var errorMessage = "Gemini API isteği başarısız oldu."
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    errorMessage += " İstek zaman aşımına uğradı."
                case .notConnectedToInternet:
                    errorMessage += " İnternet bağlantısı yok."
                case .badServerResponse:
                    errorMessage += " Sunucu yanıtı geçersiz."
                default:
                    errorMessage += " Hata kodu: \(urlError.code.rawValue)"
                }
            } else {
                errorMessage += " \(error.localizedDescription)"
            }
            
            return errorMessage
        }
    }
    
    // Yeni Metod: Konuşma geçmişi ve sistem talimatlarıyla birlikte bir istek göndermek için
    func askGeminiWithContext(systemInstruction: String, conversationHistory: [[String: Any]], query: String) async throws -> String {
        // API anahtarı kontrolü
        if apiKey.isEmpty {
            print("❌ API anahtarı tanımlanmamış")
            return "API anahtarı tanımlanmamış. Lütfen Config/APIKeys.swift dosyasında apiKey değişkenini güncelleyin."
        }
        
        // Gemini API'si zaten HTTPS kullanıyor
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        print("🤖 Gemini API çağrısı yapılıyor (konuşma geçmişiyle): \(url)")
        
        // Konuşma geçmişi ve yeni sorguyu hazırlayalım
        var updatedContents: [[String: Any]] = conversationHistory
        
        // Son kullanıcı sorgusunu ekle (eğer zaten eklenmemişse)
        if let lastContent = updatedContents.last,
           let role = lastContent["role"] as? String,
           role != "user" {
            // Değilse yeni kullanıcı sorgusunu ekle
            updatedContents.append([
                "role": "user",
                "parts": [
                    ["text": query]
                ]
            ])
        }
        
        // Gemini istek gövdesi - v1beta formatına uygun olarak
        let requestBody: [String: Any] = [
            "contents": updatedContents,
            "systemInstruction": [
                "parts": [
                    ["text": systemInstruction]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 800
            ]
        ]
        
        // Debug için JSON çıktısını da yazdıralım
        do {
            let debugJsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [.prettyPrinted])
            if let jsonString = String(data: debugJsonData, encoding: .utf8) {
                print("📝 API istek JSON: \n\(jsonString)")
            }
        } catch {
            print("Debug JSON yazdırma hatası: \(error)")
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Geçersiz yanıt: HTTP yanıtı alınamadı")
                throw URLError(.badServerResponse)
            }
            
            // Yanıtı işle
            if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                print("📡 Gemini API yanıt kodu: \(httpResponse.statusCode)")
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    // Debug çıktısı
                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject ?? [:], options: [.prettyPrinted]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("✅ API Yanıtı: \(jsonString)")
                    }
                    
                    // Yanıt formatı v1beta: candidates > content > parts > text
                    if let candidates = jsonObject?["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        return text
                    } else {
                        print("❌ Yanıt formatı beklenen gibi değil")
                        return "AI yanıtı alınamadı. Lütfen daha sonra tekrar deneyin."
                    }
                } catch {
                    print("❌ JSON ayrıştırma hatası: \(error)")
                    return "Yanıt ayrıştırılırken hata oluştu: \(error.localizedDescription)"
                }
            } else {
                // Hata mesajını yazdıralım
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ API Hata Yanıtı: \(errorString)")
                }
                throw URLError(.badServerResponse)
            }
            
        } catch {
            print("❌ API çağrısı sırasında hata: \(error.localizedDescription)")
            
            // Daha detaylı hata mesajı oluştur
            var errorMessage = "Gemini API isteği başarısız oldu."
            
            if let urlError = error as? URLError {
                switch urlError.code {
                case .timedOut:
                    errorMessage += " İstek zaman aşımına uğradı."
                case .notConnectedToInternet:
                    errorMessage += " İnternet bağlantısı yok."
                case .badServerResponse:
                    errorMessage += " Sunucu yanıtı geçersiz."
                default:
                    errorMessage += " Hata kodu: \(urlError.code.rawValue)"
                }
            } else {
                errorMessage += " \(error.localizedDescription)"
            }
            
            return errorMessage
        }
    }
} 