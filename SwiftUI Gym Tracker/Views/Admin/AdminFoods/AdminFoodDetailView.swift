import SwiftUI
import FirebaseFirestore

struct AdminFoodDetailView: View {
    let food: Food
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("Yiyecek Bilgileri")) {
                VStack(alignment: .leading, spacing: 8) {
                    if let imageUrl = food.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    Text(food.name)
                        .font(.title2)
                        .bold()
                }
            }
            
            Section(header: Text("Besin Değerleri")) {
                HStack {
                    Text("Kalori:")
                    Spacer()
                    Text("\(Int(food.calories)) kcal")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Protein:")
                    Spacer()
                    Text("\(Int(food.protein))g")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Karbonhidrat:")
                    Spacer()
                    Text("\(Int(food.carbs))g")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Yağ:")
                    Spacer()
                    Text("\(Int(food.fat))g")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Oluşturma Bilgileri")) {
                HStack {
                    Text("Oluşturan:")
                    Spacer()
                    Text(food.createdBy)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Oluşturma Tarihi:")
                    Spacer()
                    Text(food.createdAt.dateValue().formatted(date: .long, time: .shortened))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Son Güncelleme:")
                    Spacer()
                    Text(food.updatedAt.dateValue().formatted(date: .long, time: .shortened))
                        .foregroundColor(.secondary)
                }
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Yiyecek Detayı")
        .toolbar {
            Menu {
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
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AdminEditFoodView(food: food)
        }
        .alert("Yiyeceği Sil", isPresented: $showingDeleteAlert) {
            Button("Sil", role: .destructive) {
                deleteFood()
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu yiyeceği silmek istediğinize emin misiniz?")
        }
    }
    
    private func deleteFood() {
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document(food.id!)
                    .delete()
                dismiss()
            } catch {
                errorMessage = "Yiyecek silinirken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
} 
