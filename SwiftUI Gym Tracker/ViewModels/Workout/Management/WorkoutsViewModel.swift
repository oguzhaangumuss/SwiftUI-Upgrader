//
// WorkoutsViewModel.swift
//
// Purpose: Core ViewModel for managing all workout-related data and operations.
//
// Responsibilities:
// - Fetches, adds, updates, and deletes workouts
// - Provides workout filtering by date
// - Manages workout exercises
// - Calculates workout statistics (total sets, estimated time, total weight)
//
// Relationships:
// - Serves as the main data source for workout views
// - Works with the Workout model
// - Depends on FirebaseManager for database operations
// - Singleton instance shared across the app

import SwiftUI
import FirebaseFirestore
import Foundation
import FirebaseAuth

class WorkoutsViewModel: ObservableObject {
    static let shared = WorkoutsViewModel()
    
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedWorkout: Workout?
    @Published var showError = false
    
    private let db = FirebaseManager.shared.firestore
    private let userId = Auth.auth().currentUser?.uid
    
    private init() {}
    
    // MARK: - Fetch Methods
    
    @MainActor
    func fetchWorkouts() {
        guard let userId = userId else {
            self.errorMessage = "Kullanıcı oturumu bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let snapshot = try await db.collection("workouts")
                    .whereField("userId", isEqualTo: userId)
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
                
                let fetchedWorkouts = snapshot.documents.compactMap { document -> Workout? in
                    try? document.data(as: Workout.self)
                }
                
                await MainActor.run {
                    self.workouts = fetchedWorkouts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Antrenmanlar yüklenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    @MainActor
    func fetchWorkouts(for date: Date) async {
        guard let userId = userId else {
            self.errorMessage = "Kullanıcı oturumu bulunamadı"
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        isLoading = true
        errorMessage = nil
        
        do {
            let snapshot = try await db.collection("workouts")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
            
            let fetchedWorkouts = snapshot.documents.compactMap { document -> Workout? in
                try? document.data(as: Workout.self)
            }
            
            self.workouts = fetchedWorkouts
            self.isLoading = false
        } catch {
            self.errorMessage = "Antrenmanlar yüklenirken hata oluştu: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func getWorkout(by id: String) -> Workout? {
        return workouts.first(where: { $0.id == id })
    }
    
    // MARK: - Add Methods
    
    @MainActor
    func addWorkout(_ workout: Workout, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = userId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        var newWorkout = workout
        newWorkout.userId = userId
        newWorkout.createdAt = Timestamp(date: Date())
        
        do {
            let _ = try db.collection("workouts").addDocument(from: newWorkout)
            fetchWorkouts()
            completion(true, nil)
        } catch {
            completion(false, "Antrenman eklenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // Async/await version of addWorkout
    @MainActor
    func addWorkout(_ workout: Workout) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            addWorkout(workout) { success, error in
                if success {
                    continuation.resume()
                } else {
                    let nsError = NSError(
                        domain: "WorkoutsViewModel",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: error ?? "Bilinmeyen hata"]
                    )
                    continuation.resume(throwing: nsError)
                }
            }
        }
    }
    
    @MainActor
    func addExerciseToWorkout(workoutId: String, exercise: Exercise, sets: Int, reps: Int, weight: Double, notes: String? = nil) async throws {
        guard let workoutIndex = workouts.firstIndex(where: { $0.id == workoutId }) else {
            throw NSError(domain: "WorkoutsViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Antrenman bulunamadı"])
        }
        
        isLoading = true
        errorMessage = nil
        
        var updatedWorkout = workouts[workoutIndex]
        
        // Yeni egzersiz ekleyelim
        let newExercise = Workout.WorkoutExercise(
            id: UUID().uuidString,
            exerciseId: exercise.id ?? "",
            exerciseName: exercise.name,
            sets: sets,
            reps: reps,
            weight: weight,
            notes: notes
        )
        
        var updatedExercises = updatedWorkout.exercises
        updatedExercises.append(newExercise)
        
        // Güncellenen antrenmana yeni özellikleri atalım
        updatedWorkout.exercises = updatedExercises
        updatedWorkout.totalWeight += (weight * Double(sets))
        
        do {
            if let id = updatedWorkout.id {
                try await db.collection("workouts")
                    .document(id)
                    .setData(from: updatedWorkout, merge: true)
                
                // Yerel workout listesini güncelleyelim
                workouts[workoutIndex] = updatedWorkout
                
                print("✅ Egzersiz antrenmana başarıyla eklendi")
            } else {
                throw NSError(domain: "WorkoutsViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz antrenman ID'si"])
            }
        } catch {
            errorMessage = "Egzersiz eklenemedi: \(error.localizedDescription)"
            showError = true
            print("❌ Egzersiz ekleme hatası: \(error.localizedDescription)")
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Update Methods
    
    @MainActor
    func updateWorkout(_ workout: Workout, completion: @escaping (Bool, String?) -> Void) {
        guard let id = workout.id else {
            completion(false, "Geçersiz antrenman ID'si")
            return
        }
        
        do {
            try db.collection("workouts").document(id).setData(from: workout, merge: true)
            
            if let index = workouts.firstIndex(where: { $0.id == id }) {
                workouts[index] = workout
            }
            
            completion(true, nil)
        } catch {
            completion(false, "Antrenman güncellenirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Methods
    
    @MainActor
    func deleteWorkout(id: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("workouts").document(id).delete { error in
            if let error = error {
                completion(false, "Antrenman silinirken hata oluştu: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.workouts.removeAll(where: { $0.id == id })
                }
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    func getExerciseNames(for workout: Workout) -> [String] {
        return workout.exercises.map { $0.exerciseName }
    }
    
    func getTotalSets(for workout: Workout) -> Int {
        return workout.exercises.reduce(0) { $0 + $1.sets }
    }
    
    func getEstimatedTime(for workout: Workout) -> Int {
        // Her egzersiz için ortalama 3 dakika + her set için 1 dakika
        let totalSets = getTotalSets(for: workout)
        let exerciseBaseTime = workout.exercises.count * 3
        return exerciseBaseTime + totalSets
    }
    
    func getTotalWeight(for workout: Workout) -> Double {
        return workout.exercises.reduce(0) { total, exercise in
            return total + exercise.weight
        }
    }
} 
