import SwiftUI
import Foundation

/// Exercise için kategori ve görünüm uzantıları
extension Exercise {
    enum Category: String, CaseIterable, Identifiable {
        case strength = "Kuvvet"
        case cardio = "Kardiyo"
        case flexibility = "Esneklik"
        case balance = "Denge"
        case other = "Diğer"
        
        var id: String { self.rawValue }
        var title: String { self.rawValue }
    }
    
    var exerciseCategory: Category {
        if muscleGroups.contains(.cardio) {
            return .cardio
        } else if muscleGroups.contains(.fullBody) {
            return .balance
        } else if muscleGroups.contains(.core) {
            return .flexibility
        } else if !muscleGroups.isEmpty {
            return .strength
        } else {
            return .other
        }
    }
    
    var intensity: String {
        guard let met = metValue else { return "Orta" }
        
        if met < 3.0 {
            return "Düşük"
        } else if met < 6.0 {
            return "Orta"
        } else {
            return "Yüksek"
        }
    }
    
    var primaryMuscles: [String] {
        return muscleGroups.map { $0.rawValue }
    }
}

extension Exercise.Category {
    var color: Color {
        switch self {
        case .strength:
            return Color.red
        case .cardio:
            return Color.green
        case .flexibility:
            return Color.blue
        case .balance:
            return Color.purple
        case .other:
            return Color.orange
        }
    }
    
    var icon: String {
        switch self {
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "heart.fill"
        case .flexibility:
            return "figure.flexibility"
        case .balance:
            return "figure.mind.and.body"
        case .other:
            return "sparkles"
        }
    }
} 