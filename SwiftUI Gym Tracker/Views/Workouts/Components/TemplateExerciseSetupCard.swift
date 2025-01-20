//
//  TemplateExerciseSetupCard.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 12.01.2025.
//

import SwiftUI

struct TemplateExerciseSetupCard: View {
    @Binding var exercise: TemplateExercise
    var onDelete: () -> Void
    
    // Tüm setler için ortak değerler
    @State private var commonWeight: Double = 0
    @State private var commonReps: Int = 0
    @State private var numberOfSets: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            // Ortak değerler için input alanları
            HStack(spacing: 16) {
                // Set sayısı
                VStack {
                    Text("Set Sayısı")
                        .font(.caption)
                    TextField("0", value: $numberOfSets, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        .onChange(of: numberOfSets) { newValue in
                            updateExercise()
                        }
                }
                
                // Ağırlık
                VStack {
                    Text("Kg")
                        .font(.caption)
                    TextField("0", value: $commonWeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .keyboardType(.decimalPad)
                        .onChange(of: commonWeight) { newValue in
                            updateExercise()
                        }
                }
                
                // Tekrar
                VStack {
                    Text("Tekrar")
                        .font(.caption)
                    TextField("0", value: $commonReps, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        .onChange(of: commonReps) { newValue in
                            updateExercise()
                        }
                }
            }
            .padding(.vertical, 8)
            
            // Set önizleme
            ForEach(0..<numberOfSets, id: \.self) { index in
                HStack {
                    Text("Set \(index + 1)")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(commonWeight)) kg × \(commonReps) tekrar")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
        .onAppear {
            // Initial values
            numberOfSets = exercise.sets
            commonReps = exercise.reps
            commonWeight = exercise.weight ?? 0
        }
    }
    
    private var headerView: some View {
        HStack {
            Text(exercise.exerciseName)
                .font(.headline)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func updateExercise() {
        exercise.sets = max(1, numberOfSets) // En az 1 set olmalı
        exercise.reps = max(0, commonReps)
        exercise.weight = max(0, commonWeight)
    }
}

#Preview {
    TemplateExerciseSetupCard(
        exercise: .constant(
            TemplateExercise(
                id: "1",
                exerciseId: "ex1",
                exerciseName: "Bench Press",
                sets: 3,
                reps: 10,
                weight: 60.0
            )
        ),
        onDelete: {}
    )
}
