//
// ActiveWorkoutViewModel.swift
//
// Purpose: Manages the active workout session's state and functionality.
//
// Responsibilities:
// - Tracks active exercises during a workout session
// - Manages workout timer and elapsed time
// - Handles saving completed workouts to Firestore
// - Calculates workout metrics (total weight, calories burned)
// - Provides real-time updates for the active workout UI
//
// Relationships:
// - Works with WorkoutHistory model for saving completed workouts
// - Depends on FirebaseManager for database operations
// - Provides data for ActiveWorkoutView

import SwiftUI
import FirebaseFirestore
import Foundation

class ActiveWorkoutViewModel: ObservableObject {
    // Singleton instance
    static let shared = ActiveWorkoutViewModel()
    
    @Published var exercises: [ActiveExercise] = []
    @Published var elapsedTime: Double = 0
    private var timer: Timer?
    private var startTime: Date = Date()
    @Published var workoutName: String = "Antrenman"
    @Published var templateId: String? = nil
    @Published var templateName: String = ""
    
    // Private initializer for singleton pattern
    private init() {}
    
    // Method to set up a new workout from a template
    func setupNewWorkout(name: String, templateId: String?, templateName: String, exercises: [ActiveExercise]) {
        self.workoutName = name
        self.templateId = templateId
        self.templateName = templateName
        self.exercises = exercises
        self.elapsedTime = 0
        self.startTime = Date()
        startTimer()
    }
    
    func setupExercises(_ exercises: [ActiveExercise]) {
        self.exercises = exercises
        startTime = Date()
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime = Date().timeIntervalSince(self?.startTime ?? Date())
        }
    }
    
    func saveWorkout() async {
        if exercises.count == 1 {
            workoutName = exercises[0].exerciseName
        }
        
        let workoutHistory = WorkoutHistory(
            id: UUID().uuidString,
            userId: FirebaseManager.shared.currentUser?.id ?? "",
            templateId: templateId,
            templateName: templateName.isEmpty ? workoutName : templateName,
            date: Timestamp(date: Date()),
            duration: elapsedTime,
            totalWeight: calculateTotalWeight(),
            caloriesBurned: await calculateCaloriesBurned(duration: elapsedTime),
            exercises: exercises.map { exercise in
                WorkoutHistory.HistoryExercise(
                    id: UUID().uuidString,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    sets: exercise.sets.count,
                    weight: exercise.sets.first?.weight ?? 0
                )
            }
        )
        
        do {
            try await FirebaseManager.shared.firestore
                .collection("workoutHistory")
                .document(workoutHistory.id)
                .setData(workoutHistory.toDictionary())
            
            print("✅ Antrenman başarıyla kaydedildi")
        } catch {
            print("❌ Antrenman kaydedilirken hata: \(error.localizedDescription)")
        }
    }
    
    private func calculateTotalWeight() -> Double {
        var total: Double = 0
        for exercise in exercises {
            for set in exercise.sets {
                total += set.weight
            }
        }
        return total
    }
    
    private func calculateCaloriesBurned(duration: Double) async -> Double {
        // Her egzersiz için kalori hesapla
        var totalCalories: Double = 0
        
        for exercise in exercises {
            if let exerciseData = try? await FirebaseManager.shared.firestore
                .collection("exercises")
                .document(exercise.exerciseId)
                .getDocument()
                .data(as: Exercise.self) {
                
                if let calories = exerciseData.calculateCalories(
                    weight: FirebaseManager.shared.currentUser?.weight ?? 70,
                    duration: duration
                ) {
                    totalCalories += calories
                }
            }
        }
        
        return totalCalories
    }
    
    func resetTimer() {
        startTime = Date()
        elapsedTime = 0
    }
    
    func removeExercise(_ exercise: ActiveExercise) {
        exercises.removeAll { $0.id == exercise.id }
        
        // Eğer son egzersiz silindiyse antrenman adını güncelle
        if exercises.isEmpty {
            workoutName = "Antrenman"
        } else if exercises.count == 1 {
            // Tek egzersiz kaldıysa onun adını kullan
            workoutName = exercises[0].exerciseName
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}



