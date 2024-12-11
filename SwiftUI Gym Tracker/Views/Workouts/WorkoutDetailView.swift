import SwiftUI
import FirebaseFirestore

struct WorkoutDetailView: View {
    let workout: UserExercise
    
    var body: some View {
        Form {
            Section(header: Text("Antrenman Detayları")) {
                LabeledContent("Egzersiz", value: workout.exerciseName ?? "Bilinmeyen Egzersiz")
                LabeledContent("Set", value: "\(workout.sets)")
                LabeledContent("Tekrar", value: "\(workout.reps)")
                LabeledContent("Ağırlık", value: "\(Int(workout.weight)) kg")
                
                LabeledContent("Süre", value: "\(Int(workout.duration/60)) dakika")
                
                if let calories = workout.caloriesBurned {
                    LabeledContent("Yakılan Kalori", value: "\(Int(calories)) kcal")
                }
            }
            
            if let notes = workout.notes, !notes.isEmpty {
                Section(header: Text("Notlar")) {
                    Text(notes)
                }
            }
            
            Section(header: Text("Tarih Bilgileri")) {
                LabeledContent("Tarih", value: workout.date.dateValue().formatted(date: .long, time: .omitted))
                LabeledContent("Oluşturulma", value: workout.createdAt.dateValue().formatted())
            }
        }
        .navigationTitle("Antrenman Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
} 
