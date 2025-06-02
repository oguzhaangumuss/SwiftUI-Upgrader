// 
//  AddToWorkoutView.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 12.01.2025.
//

// Bu view antrenmana egzersiz ekler.


import SwiftUI
import FirebaseFirestore
import Foundation

struct AddToWorkoutView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // View Models
    @EnvironmentObject var exercisesViewModel: ExercisesViewModel
    @EnvironmentObject var workoutsViewModel: WorkoutsViewModel
    @ObservedObject var firebaseManager = FirebaseManager.shared
    
    let exercise: Exercise
    
    // Form values
    @State private var selectedDate = Date()
    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var notes = ""
    @State private var duration = ""
    
    // UI State
    @State private var showingDeleteAlert = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isLoading = false
    @State private var showSuccess = false
    
    // Yeni state değişkenleri
    @State private var workoutsForSelectedDate: [Workout] = []
    @State private var selectedWorkoutId: String? = nil
    @State private var showWorkoutSelector: Bool = false
    
    // Calculate burned calories
    private var caloriesBurned: Int {
        guard let durationValue = Double(duration),
              let userWeight = firebaseManager.currentUser?.weight else {
            return 0
        }
        
        let intensityFactor: Double
        switch exercise.intensity {
        case "Düşük":
            intensityFactor = 3
        case "Orta":
            intensityFactor = 5
        case "Yüksek":
            intensityFactor = 7
        default:
            intensityFactor = 5
        }
        
        // Calories burned = (MET value * weight in kg * duration in hours)
        let hoursValue = durationValue / 60.0
        let calories = intensityFactor * userWeight * hoursValue
        return Int(calories)
    }
    
    var formIsValid: Bool {
        return !sets.isEmpty && !reps.isEmpty
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise Hero Card
                    exerciseCard
                    
                    // Form
                    VStack(spacing: 24) {
                        // Date picker section
                        formSection(title: "Tarih") {
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding(.horizontal)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .onChange(of: selectedDate) { _ in
                                    onDateSelected()
                                }
                                .onAppear {
                                    onDateSelected()
                                }
                        }
                        
                        // Workout selector if available
                        if showWorkoutSelector {
                            workoutSelector
                        }
                        
                        // Exercise details section
                        formSection(title: "Antrenman Detayları") {
                            VStack(spacing: 16) {
                                // Sets and reps row
                                HStack(spacing: 12) {
                                    // Sets input
                                    numericInput(title: "Setler", value: $sets, placeholder: "0", keyboardType: .numberPad)
                                    
                                    // Reps input
                                    numericInput(title: "Tekrarlar", value: $reps, placeholder: "0", keyboardType: .numberPad)
                                }
                                
                                // Weight and duration row
                                HStack(spacing: 12) {
                                    // Weight input
                                    numericInput(title: "Ağırlık (kg)", value: $weight, placeholder: "0", keyboardType: .decimalPad)
                                    
                                    // Duration input
                                    numericInput(title: "Süre (dk)", value: $duration, placeholder: "0", keyboardType: .numberPad)
                                }
                                
                                // Notes input
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notlar")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                    
                    TextEditor(text: $notes)
                                        .frame(minHeight: 100)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .overlay(
                                            Group {
                                                if notes.isEmpty {
                                                    Text("Antrenman hakkında notlarınızı buraya ekleyin...")
                                                        .foregroundColor(Color.gray.opacity(0.6))
                                                        .padding(.leading, 15)
                                                        .padding(.top, 15)
                                                        .allowsHitTesting(false)
                                                }
                                            }
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Calories burned card
                        if !duration.isEmpty, let userWeight = firebaseManager.currentUser?.weight {
                            calorieCard
                        }
                        
                        // Add to workout button
                        addToWorkoutButton
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Antrenmana Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .foregroundColor(.white)
                    )
            }
            
            // Success notification
            if showSuccess {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Antrenmana başarıyla eklendi!")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showSuccess = false
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .zIndex(1)
                .transition(.opacity)
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Hata"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    // MARK: - Component Views
    
    // Tarih seçildiğinde çalışacak fonksiyon
    private func onDateSelected() {
        Task {
            await workoutsViewModel.fetchWorkouts(for: selectedDate)
            DispatchQueue.main.async {
                workoutsForSelectedDate = workoutsViewModel.workouts
                showWorkoutSelector = !workoutsForSelectedDate.isEmpty
                if workoutsForSelectedDate.isEmpty {
                    selectedWorkoutId = nil
                }
            }
        }
    }
    
    // Workout seçici bileşeni
    private var workoutSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bu tarihte mevcut antrenmanlar")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)
            
            ForEach(workoutsForSelectedDate) { workout in
                WorkoutSelectorRow(
                    workout: workout,
                    isSelected: selectedWorkoutId == workout.id,
                    onSelect: {
                        selectedWorkoutId = workout.id
                    }
                )
            }
            
            Button(action: {
                selectedWorkoutId = nil
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Yeni Antrenman Oluştur")
                        .fontWeight(.medium)
                }
                .padding(.vertical, 8)
            }
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Exercise card displaying exercise info
    private var exerciseCard: some View {
        let category = exercise.exerciseCategory
        let categoryColor = category.color
        let categoryIcon = category.icon
        let categoryTitle = category.title
        
        return VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Category background color
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            categoryColor.opacity(0.7),
                            categoryColor.opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 160)
                
                // Exercise info
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: categoryIcon)
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text(categoryTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        if let primaryMuscle = exercise.muscleGroups.first {
                            Text(primaryMuscle.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
        }
    }
    
    // Form section with title and content
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            content()
        }
    }
    
    // Numeric input field with title and placeholder
    private func numericInput(title: String, value: Binding<String>, placeholder: String, keyboardType: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: value)
                .keyboardType(keyboardType)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    // Calories burned info card
    private var calorieCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tahmini Yakılan Kalori")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(caloriesBurned) kcal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundColor(.orange)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    // Add to workout button
    private var addToWorkoutButton: some View {
        Button(action: addToWorkout) {
            Text("Antrenmana Ekle")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(formIsValid ? exercise.exerciseCategory.color : Color.gray)
                )
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .disabled(!formIsValid)
    }
    
    // MARK: - Action Methods
    
    private func addToWorkout() {
        guard formIsValid else {
            errorMessage = "Lütfen tüm gerekli alanları doldurun"
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if let selectedId = selectedWorkoutId, !selectedId.isEmpty {
                    // Mevcut antrenmana egzersiz ekle
                    try await workoutsViewModel.addExerciseToWorkout(
                        workoutId: selectedId,
                        exercise: exercise,
                        sets: Int(sets) ?? 0,
                        reps: Int(reps) ?? 0,
                        weight: Double(weight) ?? 0,
                        notes: notes.isEmpty ? nil : notes
                    )
                } else {
                    // Yeni antrenman oluştur (mevcut davranış)
                    let weight = Double(self.weight) ?? 0
                    let repsInt = Int(reps) ?? 0
                    let setsInt = Int(sets) ?? 0
                    let durationInt = Int(duration) ?? 0
                    
                    let workout = Workout(
                        name: exercise.name,
                        sets: setsInt,
                        reps: repsInt,
                        weight: weight,
                        date: selectedDate,
                        notes: notes.isEmpty ? "" : notes,
                        duration: durationInt,
                        caloriesBurned: caloriesBurned,
                        exerciseId: exercise.id ?? ""
                    )
                    
                    try await workoutsViewModel.addWorkout(workout) { success, error in
                        if !success, let errorMsg = error {
                            errorMessage = errorMsg
                            showingError = true
                        }
                    }
                }
                
                isLoading = false
                
                withAnimation {
                    showSuccess = true
                }
            } catch {
                isLoading = false
                errorMessage = "Antrenman eklenemedi: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// Workout seçici satır bileşeni
struct WorkoutSelectorRow: View {
    let workout: Workout
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.templateName)
                        .font(.headline)
                    
                    Text("\(workout.exercises.count) egzersiz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// TextEditor için placeholder eklentisi
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 
