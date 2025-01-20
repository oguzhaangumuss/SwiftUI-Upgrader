import SwiftUI

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TemplateDetailViewModel
    @State private var showingActiveWorkout = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    init(template: WorkoutTemplate) {
        _viewModel = StateObject(wrappedValue: TemplateDetailViewModel(template: template))
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Başlık ve Menü Butonu
                HStack {
                    Text(viewModel.template.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Şablonu Düzenle", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Şablonu Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                            .font(.title2)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Egzersiz Kartları
                ForEach(viewModel.template.exercises) { exercise in
                    ExerciseCard(exercise: exercise)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Antrenmanı Başlat Butonu
                Button {
                    showingActiveWorkout = true
                } label: {
                    HStack {
                        Text("Antrenmanı Başlat")
                            .fontWeight(.semibold)
                        Image(systemName: "play.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            ActiveWorkoutView(template: viewModel.template)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTemplateView(
                template: viewModel.template
            )
        }
        .alert("Şablonu Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                Task {
                    await viewModel.deleteTemplate(viewModel.template)
                    dismiss()
                }
            }
        } message: {
            Text("Bu şablonu silmek istediğinize emin misiniz?")
        }
    }
}

// Egzersiz Kartı Bileşeni
struct ExerciseCard: View {
    let exercise: TemplateExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
            
            HStack(spacing: 24) {
                ExerciseInfoView(title: "Set", value: "\(exercise.sets)")
                ExerciseInfoView(title: "Tekrar", value: "\(exercise.reps)")
                ExerciseInfoView(title: "Kilo", value: "\(exercise.weight) kg")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

