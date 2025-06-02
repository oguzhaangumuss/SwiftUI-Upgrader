//
//  ExercisesView.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 12.01.2025.
//

import SwiftUI
import Firebase

struct ExercisesView: View {
    @StateObject private var viewModel = ExercisesViewModel()
    @State private var searchText = ""
    @State private var showAddExercise = false
    @State private var showingErrorToast = false
    @State private var errorMessage = ""
    @State private var isShowingActionSheet = false
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            if let selectedGroup = viewModel.selectedMuscleGroup {
                return viewModel.exercises.filter { exercise in
                    exercise.muscleGroups.contains(where: { $0.id == selectedGroup.id })
                }
            }
            return viewModel.exercises
        } else {
            var filtered = viewModel.exercises.filter { exercise in
                exercise.name.lowercased().contains(searchText.lowercased())
            }
            
            if let selectedGroup = viewModel.selectedMuscleGroup {
                filtered = filtered.filter { exercise in
                    exercise.muscleGroups.contains(where: { $0.id == selectedGroup.id })
                }
            }
            
            return filtered
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search Bar
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Egzersiz Ara", text: $searchText)
                                .foregroundColor(.primary)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                        
                        // Muscle Group Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterButton(
                                    title: "Tümü",
                                    isSelected: viewModel.selectedMuscleGroup == nil,
                                    action: {
                                        withAnimation(.spring()) {
                                            viewModel.selectedMuscleGroup = nil
                                        }
                                    }
                                )
                                
                                ForEach(viewModel.muscleGroups) { muscleGroup in
                                    FilterButton(
                                        title: muscleGroup.name,
                                        isSelected: viewModel.selectedMuscleGroup?.id == muscleGroup.id,
                                        action: {
                                            withAnimation(.spring()) {
                                                if viewModel.selectedMuscleGroup?.id == muscleGroup.id {
                                                    viewModel.selectedMuscleGroup = nil
                                                } else {
                                                    viewModel.selectedMuscleGroup = muscleGroup
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                    .padding(.top)
                    .background(Color(UIColor.systemBackground))
                    .zIndex(1)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    
                    if viewModel.isLoading {
                        LoadingView()
                    } else if filteredExercises.isEmpty {
                        ExerciseEmptyStateView(
                            title: "Egzersiz Bulunamadı",
                            message: viewModel.selectedMuscleGroup != nil ? 
                                "Bu kas grubunda egzersiz bulunmuyor. Farklı bir kas grubu seçin veya yeni bir egzersiz ekleyin." : 
                                "Arama kriterlerinize uygun egzersiz bulunamadı. Aramanızı değiştirin veya yeni bir egzersiz ekleyin.",
                            imageName: "dumbbell.fill"
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)], spacing: 16) {
                                ForEach(filteredExercises) { exercise in
                                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                        ExerciseCard(exercise: exercise)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // Error Toast
                VStack {
                    Spacer()
                    if showingErrorToast {
                        ErrorToast(message: errorMessage) {
                            withAnimation {
                                showingErrorToast = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("Egzersizler")
            .navigationBarItems(trailing: Button(action: {
                isShowingActionSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.blue)
            })
            .actionSheet(isPresented: $isShowingActionSheet) {
                ActionSheet(
                    title: Text("Egzersiz Ekleme Seçenekleri"),
                    message: Text("Ne tür bir egzersiz eklemek istersiniz?"),
                    buttons: [
                        .default(Text("Manuel Egzersiz Ekle")) {
                            showAddExercise = true
                        },
                        .cancel(Text("İptal"))
                    ]
                )
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView()
            }
            .onAppear {
                viewModel.fetchExercisesWrapper()
                viewModel.fetchMuscleGroups()
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? 
                              Color.blue.opacity(0.15) : 
                              Color(UIColor.secondarySystemBackground)
                        )
                        .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
                .foregroundColor(isSelected ? Color.blue : Color.primary)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and Muscle Group
            HStack(alignment: .top) {
                Image(systemName: exercise.exerciseCategory.icon)
                    .font(.title2)
                    .frame(width: 28, height: 28)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [exercise.exerciseCategory.color.opacity(0.7), exercise.exerciseCategory.color.opacity(0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .foregroundColor(.white)
                
                Spacer()
                
                if !exercise.muscleGroups.isEmpty {
                    Text(exercise.muscleGroups.first?.rawValue ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                        )
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Name
            Text(exercise.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Muscle Groups Count
            if exercise.muscleGroups.count > 1 {
                Text("\(exercise.muscleGroups.count) Kas Grubu")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 130)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ExerciseEmptyStateView: View {
    let title: String
    let message: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
                .padding(24)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Egzersizler Yükleniyor...")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorToast: View {
    let message: String
    let dismissAction: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.9))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .transition(.move(edge: .bottom))
        .animation(.spring())
    }
}

struct ExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        ExercisesView()
            .preferredColorScheme(.dark)
    }
}

