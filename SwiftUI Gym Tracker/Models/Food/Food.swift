import FirebaseFirestore
import SwiftUI

struct Food: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let brand: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let imageUrl: String?
    let createdBy: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    var category: String?
    
    // Kategori enumu
    enum Category: String, CaseIterable, Codable {
        case protein = "Protein Kaynakları"
        case dairy = "Süt Ürünleri"
        case grains = "Tahıllar"
        case fruits = "Meyveler"
        case vegetables = "Sebzeler"
        case snacks = "Atıştırmalıklar"
        case beverages = "İçecekler"
        case other = "Diğer"
        
        var title: String {
            return self.rawValue
        }
        
        var icon: String {
            switch self {
            case .protein: return "fish"
            case .dairy: return "cup.and.saucer"
            case .grains: return "triangle"
            case .fruits: return "applelogo"
            case .vegetables: return "leaf"
            case .snacks: return "birthday.cake"
            case .beverages: return "mug"
            case .other: return "questionmark"
            }
        }
        
        var color: Color {
            switch self {
            case .protein: return Color.red
            case .dairy: return Color.blue
            case .grains: return Color.orange
            case .fruits: return Color.purple
            case .vegetables: return Color.green
            case .snacks: return Color.pink
            case .beverages: return Color.cyan
            case .other: return Color.gray
            }
        }
    }
    
    // Kategori alma fonksiyonu
    var foodCategory: Category {
        guard let category = category else {
            return .other
        }
        
        return Category(rawValue: category) ?? .other
    }
} 
