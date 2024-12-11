import SwiftUI
import FirebaseFirestore

struct AdminExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Egzersiz Bilgileri")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title2)
                        .bold()
                    
                    Text(exercise.description)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Kas Grupları")) {
                ForEach(exercise.muscleGroups, id: \.self) { group in
                    Text(group.rawValue)
                }
            }
            
            Section(header: Text("Değerlendirme")) {
                HStack {
                    Text("Ortalama Puan")
                    Spacer()
                    if let rating = exercise.averageRating {
                        Text(String(format: "%.1f", rating))
                    } else {
                        Text("Henüz değerlendirilmemiş")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Toplam Değerlendirme")
                    Spacer()
                    Text("\(exercise.totalRatings)")
                }
            }
            
            if let metValue = exercise.metValue {
                Section(header: Text("MET Değeri")) {
                    Text(String(format: "%.1f", metValue))
                }
            }
            
            Section(header: Text("Tarih Bilgileri")) {
                HStack {
                    Text("Oluşturulma")
                    Spacer()
                    Text(exercise.createdAt.dateValue().formatted())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Son Güncelleme")
                    Spacer()
                    Text(exercise.updatedAt.dateValue().formatted())
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Egzersiz Detayı")
        .navigationBarItems(trailing: Menu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Düzenle", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Sil", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        })
        .alert("Egzersizi Sil", isPresented: $showingDeleteAlert) {
            Button("Sil", role: .destructive) {
                deleteExercise()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu egzersizi silmek istediğinizden emin misiniz?")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditExerciseView(exercise: exercise)
        }
    }
    
    private func deleteExercise() {
            guard let exerciseId = exercise.id else {
                print("Egzersiz ID'si bulunamadı")
                return
            }
            
            Task {
                do {
                    try await FirebaseManager.shared.firestore
                        .collection("exercises")
                        .document(exerciseId)
                        .delete()
                    dismiss()
                } catch {
                    print("Egzersiz silinemedi: \(error)")
                }
            }
        }
}
