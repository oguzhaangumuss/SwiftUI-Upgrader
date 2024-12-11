import SwiftUI
import Combine
import FirebaseFirestore

class ExercisesViewModel: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var alertItem: AlertItem?
    
    private let exerciseService: ExerciseService
    private var cancellables = Set<AnyCancellable>()
    
    init(exerciseService: ExerciseService = FirebaseExerciseService()) {
        self.exerciseService = exerciseService
        Task {
            await fetchExercises()
        }
    }
    
    @MainActor
    func fetchExercises() async {
        isLoading = true
        do {
            exercises = try await exerciseService.fetchExercises()
        } catch {
            alertItem = AlertItem(
                title: "Hata",
                message: ExerciseError.fetchFailed.localizedDescription,
                dismissButton: .default(Text("Tamam"))
            )
        }
        isLoading = false
    }
    
    func filteredExercises(for muscleGroup: MuscleGroup?) -> [Exercise] {
        guard let muscleGroup = muscleGroup else { return exercises }
        return exercises.filter { $0.muscleGroups.contains(muscleGroup) }
    }
} 
