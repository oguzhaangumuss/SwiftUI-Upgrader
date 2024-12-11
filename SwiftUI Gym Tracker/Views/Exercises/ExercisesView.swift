import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel = ExercisesViewModel()
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                muscleGroupSelector
                exerciseList
            }
            .navigationTitle("Egzersizler")
            .refreshable {
                await viewModel.fetchExercises()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    // MARK: - Filtered Exercises
    private var filteredExercises: [Exercise] {
        viewModel.exercises
            .filter { exercise in
                guard let selectedGroup = selectedMuscleGroup else { return true }
                return exercise.muscleGroups.contains(selectedGroup)
            }
            .filter { exercise in
                guard !searchText.isEmpty else { return true }
                return exercise.name.localizedCaseInsensitiveContains(searchText) ||
                       exercise.description.localizedCaseInsensitiveContains(searchText)
            }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Egzersiz Ara...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Muscle Group Selector
    private var muscleGroupSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MuscleGroup.allCases, id: \.self) { group in
                    muscleGroupButton(for: group)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
    
    private func muscleGroupButton(for group: MuscleGroup) -> some View {
        Button {
            withAnimation {
                selectedMuscleGroup = selectedMuscleGroup == group ? nil : group
            }
        } label: {
            Text(group.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedMuscleGroup == group ? Color.blue : Color.blue.opacity(0.1))
                .foregroundColor(selectedMuscleGroup == group ? .white : .blue)
                .cornerRadius(20)
        }
    }
    
    // MARK: - Exercise List
    private var exerciseList: some View {
        List {
            ForEach(filteredExercises) { exercise in
                exerciseRow(for: exercise)
            }
        }
    }
    
    private func exerciseRow(for exercise: Exercise) -> some View {
        NavigationLink {
            ExerciseDetailView(exercise: exercise)
        } label: {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.headline)
                Text(exercise.muscleGroups.map { $0.rawValue }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
} 
