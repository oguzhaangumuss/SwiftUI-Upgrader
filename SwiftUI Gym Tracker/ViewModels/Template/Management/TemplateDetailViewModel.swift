//
//  TemplateDetailViewModel.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 12.01.2025.
//
import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class TemplateDetailViewModel: BaseTemplateViewModel {
    @Published var template: WorkoutTemplate
    weak var delegate: WorkoutPlanDelegate?
    
    init(template: WorkoutTemplate) {
        self.template = template
        super.init()
    }
    
    func updateTemplate(_ updatedTemplate: WorkoutTemplate) {
        self.template = updatedTemplate
    }
    
    func deleteTemplate() async {
        startLoading()
        
        do {
            guard let templateId = template.id else {
                throw AppError.validationError("Geçersiz şablon ID'si")
            }
            
            try await repository.deleteTemplate(templateId: templateId)
            
            // Notify the delegate
            DispatchQueue.main.async {
                self.delegate?.templateDidDelete()
            }
            
            // Post notification for other ViewModels
            NotificationCenter.default.post(
                name: .templateDeleted,
                object: nil,
                userInfo: ["templateId": templateId]
            )
            
            finishLoading()
        } catch {
            finishLoading()
            handleError(error)
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
