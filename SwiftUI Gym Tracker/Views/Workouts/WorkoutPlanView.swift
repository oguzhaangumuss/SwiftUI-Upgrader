import SwiftUI
import FirebaseFirestore

struct WorkoutPlanView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tarih seçici
                HStack {
                    Button {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button {
                        showingDatePicker = true
                    } label: {
                        Text(selectedDate.formatted(date: .long, time: .omitted))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(radius: 1)
                
                // Yakılan kalori özeti
                if !viewModel.workouts.isEmpty {
                    DailyCaloriesSummary(workouts: viewModel.workouts)
                        .padding()
                }
                
                // Liste veya boş durum mesajı
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        List {
                            if viewModel.workouts.isEmpty {
                                EmptyStateView(
                                    image: "dumbbell",
                                    message: "Bu tarihte antrenman bulunmuyor"
                                )
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets())
                            } else {
                                ForEach(viewModel.workouts) { workout in
                                    WorkoutRow(workout: workout)
                                }
                                .onDelete { indexSet in
                                    Task {
                                        await viewModel.deleteWorkout(at: indexSet)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Antrenmanlarım")
            .onAppear {
                // Sayfa her göründüğünde seçili tarihin antrenmanlarını yükle
                Task {
                    await viewModel.fetchWorkouts(for: selectedDate)
                }
            }
            .onChange(of: selectedDate) { _ in
                Task {
                    await viewModel.fetchWorkouts(for: selectedDate)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate, showingDatePicker: $showingDatePicker)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshWorkouts"))) { _ in
            Task {
                await viewModel.fetchWorkouts(for: selectedDate)
            }
        }
    }
}

struct WorkoutRow: View {
    let workout: UserExercise
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.exerciseName ?? "Bilinmeyen Egzersiz")
                .font(.headline)
            
            HStack {
                Label("\(workout.sets) set", systemImage: "number.square")
                Spacer()
                Label("\(workout.reps) tekrar", systemImage: "repeat")
                Spacer()
                Label("\(Int(workout.weight)) kg", systemImage: "scalemass")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            HStack {
                Label("\(Int(workout.duration/60)) dk", systemImage: "clock")
                
                if let calories = workout.caloriesBurned {
                    Spacer()
                    Label("\(Int(calories)) kcal", systemImage: "flame")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            WorkoutDetailView(workout: workout)
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        NavigationView {
            DatePicker("Tarih Seç",
                      selection: $selectedDate,
                      displayedComponents: .date)
                .datePickerStyle(.graphical)
                .navigationTitle("Tarih Seç")
                .navigationBarItems(
                    trailing: Button("Tamam") {
                        showingDatePicker = false
                    }
                )
        }
    }
}
