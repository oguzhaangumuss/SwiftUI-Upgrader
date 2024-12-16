import SwiftUI
import FirebaseFirestore

struct AdminExercisesView: View {
    @StateObject private var viewModel = AdminExercisesViewModel()
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var searchText = ""
    
    private var filteredExercises: [Exercise] {
        let muscleGroupFiltered = selectedMuscleGroup == nil ? 
            viewModel.exercises : 
            viewModel.exercises.filter { $0.muscleGroups.contains(selectedMuscleGroup!) }
            
        if searchText.isEmpty {
            return muscleGroupFiltered
        }
        
        return muscleGroupFiltered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            muscleGroupSelector
            exerciseList
        }
        .navigationTitle("Egzersizler")
        .refreshable {
            await viewModel.fetchExercises()
        }
    }
    
    // MARK: - View Components
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
                .background(
                    selectedMuscleGroup == group ?
                    Color.blue : Color.blue.opacity(0.1)
                )
                .foregroundColor(
                    selectedMuscleGroup == group ?
                    .white : .blue
                )
                .cornerRadius(20)
        }
    }
    
    private var exerciseList: some View {
        List {
            ForEach(filteredExercises) { exercise in
                NavigationLink {
                    AdminExerciseDetailView(exercise: exercise)
                } label: {
                    ExerciseRowView(exercise: exercise)
                }
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteExercises(at: indexSet)
                }
            }
        }
    }
}
