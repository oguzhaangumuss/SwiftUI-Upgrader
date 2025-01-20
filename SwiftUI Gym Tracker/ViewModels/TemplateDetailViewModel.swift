//
//  TemplateDetailViewModel.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 12.01.2025.
//
import Foundation

class TemplateDetailViewModel: ObservableObject {
    @Published var template: WorkoutTemplate
    weak var delegate: WorkoutPlanDelegate?
    
    init(template: WorkoutTemplate) {
        self.template = template
    }
    
    func updateTemplate(_ updatedTemplate: WorkoutTemplate) {
        self.template = updatedTemplate
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) async {
        do {
            try await FirebaseManager.shared.firestore
                .collection("workoutTemplates")
                .document(template.id ?? "")
                .delete()
            
            print("✅ Şablon başarıyla silindi")
        } catch {
            print("❌ Şablon silinirken hata: \(error.localizedDescription)")
        }
    }
    
    func deleteExercise(from template: WorkoutTemplate, exercise: TemplateExercise) async {
        guard let templateId = template.id else { return }
        
        do {
            // Firebase'den sil
            var updatedExercises = template.exercises
            updatedExercises.removeAll { $0.id == exercise.id }
            
            let exerciseData = updatedExercises.map { exercise -> [String: Any] in
                [
                    "id": exercise.id,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.exerciseName,
                    "sets": exercise.sets,
                    "reps": exercise.reps,
                    "weight": exercise.weight as Any,
                    "notes": exercise.notes as Any
                ]
            }
            
            try await FirebaseManager.shared.firestore
                .collection("workoutTemplates")
                .document(templateId)
                .updateData(["exercises": exerciseData])
            
            // Yerel state'i güncelle
            await MainActor.run {
                self.template.exercises = updatedExercises  // UI güncellenecek
            }
            
            print("✅ Egzersiz başarıyla silindi")
        } catch {
            print("❌ Egzersiz silinirken hata: \(error.localizedDescription)")
        }
    }
}
