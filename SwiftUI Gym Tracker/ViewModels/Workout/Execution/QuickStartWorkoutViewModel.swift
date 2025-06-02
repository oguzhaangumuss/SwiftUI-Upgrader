import SwiftUI
import FirebaseFirestore
import Foundation


class QuickStartWorkoutViewModel: ObservableObject {
    @Published var activeExercises: [ActiveExercise] = []
    @Published var selectedExercises: [TemplateExercise] = [] {
        didSet {
            handleSelectedExercisesChange()
        }
    }
    @Published var elapsedTime: Double = 0
    @Published var isTimerRunning = false
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private var workoutStartTime: Date?
    
    // MARK: - Exercise Management
    private func handleSelectedExercisesChange() {
        guard let lastSelected = selectedExercises.last else { return }
        
        DispatchQueue.main.async { [weak self] in
            let activeExercise = ActiveExercise(
                exerciseId: lastSelected.exerciseId,
                exerciseName: lastSelected.exerciseName
            )
            self?.activeExercises.append(activeExercise)
            
            if !(self?.isTimerRunning ?? false) {
                self?.startTimer()
            }
        }
    }
    
    func addExercise(_ templateExercise: TemplateExercise) {
        let activeExercise = ActiveExercise(
            exerciseId: templateExercise.exerciseId,
            exerciseName: templateExercise.exerciseName
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.activeExercises.append(activeExercise)
            
            if !(self?.isTimerRunning ?? false) {
                self?.startTimer()
            }
        }
    }
    
    func finishWorkout() async {
        print("📝 Antrenman bitirildi")
        print("⏱️ Toplam süre: \(elapsedTime) saniye")
        print("💪 Egzersiz sayısı: \(activeExercises.count)")
        
        // Timer'ı durdur
        await MainActor.run {
            stopTimer()
        }
        
        // Verileri kopyala
        let exercisesToSave = activeExercises
        let totalTime = elapsedTime
        
        do {
            // Firestore işlemleri
            try await saveExercisesToFirestore(exercises: exercisesToSave, duration: totalTime)
            
            // UI güncellemesi
            await MainActor.run {
                // Yeni boş array'ler oluştur
                activeExercises = []
                selectedExercises = []
                elapsedTime = 0
                isTimerRunning = false
                print("\n🧹 Temizlik tamamlandı")
            }
            
        } catch {
            print("❌ Antrenman kaydedilirken hata: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Antrenman kaydedilirken bir hata oluştu"
            }
        }
    }
    
    private func saveExercisesToFirestore(exercises: [ActiveExercise], duration: Double) async throws {
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            print("❌ Kullanıcı ID'si bulunamadı")
            return
        }
        
        let db = FirebaseManager.shared.firestore
        
        print("\n🏋️‍♂️ Egzersiz detayları:")
        for exercise in exercises {
            print("\n📌 Egzersiz: \(exercise.exerciseName)")
            print("🆔 Exercise ID: \(exercise.exerciseId)")
            print("📝 Notlar: \(exercise.notes ?? "Not yok")")
            print("🎯 Setler:")
            
            let sets = exercise.sets
            for set in sets {
                let exerciseData: [String: Any] = [
                    "userId": userId,
                    "exerciseId": exercise.exerciseId,
                    "exerciseName": exercise.exerciseName,
                    "sets": set.setNumber,
                    "reps": set.reps,
                    "weight": set.weight,
                    "date": Timestamp(),
                    "notes": exercise.notes ?? "",
                    "duration": duration,
                    "createdAt": Timestamp()
                ]
                
                print("📤 Firestore'a gönderilen veri:")
                print(exerciseData)
                
                try await db.collection("userExercises").addDocument(data: exerciseData)
                print("✅ Set başarıyla kaydedildi")
            }
        }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        guard !isTimerRunning else { return }
        
        workoutStartTime = Date()
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.elapsedTime += 1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
}

