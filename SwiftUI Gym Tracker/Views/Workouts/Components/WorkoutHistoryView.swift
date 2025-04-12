import SwiftUI

struct WorkoutHistoryView: View {
    @StateObject private var viewModel = WorkoutHistoryViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Geçmiş Antrenmanlar")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            // Takvim görünümü
            WorkoutCalendarView(
                selectedDate: $viewModel.selectedDate,
                workoutDates: viewModel.workoutDates
            )
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // Seçili gündeki antrenmanlar
            if let selectedDate = viewModel.selectedDate {
                if viewModel.dailyWorkouts.isEmpty {
                    Text("Bu tarihte antrenman bulunamadı")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.dailyWorkouts) { workout in
                                WorkoutHistoryCard(workout: workout)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Text("Tarih seçin")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .task {
            await viewModel.fetchWorkoutDates()
            // Bugünün tarihini seç ve antrenmanları getir
            let today = Date()
            viewModel.selectedDate = today
            await viewModel.fetchDailyWorkouts(for: today)
        }
        .onChange(of: viewModel.selectedDate) { date in
            if let date = date {
                Task {
                    await viewModel.fetchDailyWorkouts(for: date)
                }
            }
        }
        // Yeni antrenman eklendiğinde yenileme için refreshable ekleyelim
        .refreshable {
            await viewModel.fetchWorkoutDates()
            if let selectedDate = viewModel.selectedDate {
                await viewModel.fetchDailyWorkouts(for: selectedDate)
            }
        }
    }
}

// Takvim görünümü
struct WorkoutCalendarView: View {
    @Binding var selectedDate: Date?
    let workoutDates: Set<Date>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker(
                "Tarih Seç",
                selection: Binding(
                    get: { selectedDate ?? Date() },
                    set: { selectedDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(AppTheme.primaryColor)
            
            // Antrenman olan günleri göster
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(workoutDates).sorted(), id: \.self) { date in
                        Button {
                            selectedDate = date
                        } label: {
                            Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedDate == date ? AppTheme.primaryColor : Color(.systemGray5))
                                )
                                .foregroundColor(selectedDate == date ? .white : .primary)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Date uzantısı ekleyelim
extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}

// Antrenman kartı görünümü
struct WorkoutHistoryCard: View {
    let workout: WorkoutHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Şablon ismi
            Text(workout.templateName)
                .font(.headline)
            
            // İstatistikler
            HStack(spacing: 16) {
                // Süre
                Label(workout.duration.formattedDuration, systemImage: "clock")
                
                // Toplam kilo
                Label("\(Int(workout.totalWeight)) kg", systemImage: "dumbbell.fill")
                
                // Yakılan kalori
                Label("\(Int(workout.caloriesBurned)) kcal", systemImage: "flame.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            // Egzersizler
            HStack(alignment: .top) {
                // Egzersiz isimleri
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(workout.exercises) { exercise in
                        Text(exercise.exerciseName)
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // Set bilgileri
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(workout.exercises) { exercise in
                        Text(exercise.formattedSets)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Double için formatlama extension'ı
extension Double {
    var formattedDuration: String {
        let hours = Int(self / 3600.0)
        let minutes = Int(self / 60.0) % 60
        
        if hours > 0 {
            return "\(hours) sa \(minutes) dk"
        } else {
            return "\(minutes) dk"
        }
    }
}

// TimeInterval için formatlama extension'ı
//extension TimeInterval {
//    var formattedDuration: String {
//        let hours = Int(self) / 3600
//        let minutes = Int(self) / 60 % 60
//        
//        if hours > 0 {
//            return "\(hours) sa \(minutes) dk"
//        } else {
//            return "\(minutes) dk"
//        }
//    }
//} 
