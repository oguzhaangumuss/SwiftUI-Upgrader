import SwiftUI
import FirebaseFirestore

struct FoodDetailView: View {
    let food: Food
    @Environment(\.dismiss) var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddToMealSheet = false
    @State private var errorMessage = ""
    
    private var canEditFood: Bool {
        let currentUserId = FirebaseManager.shared.auth.currentUser?.uid
        return food.createdBy == currentUserId || FirebaseManager.shared.currentUser?.isAdmin == true
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Besin Değerleri")) {
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
                
                if canEditFood {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Yiyeceği Sil")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(food.name)
            .navigationBarItems(
                leading: Button("Kapat") { dismiss() },
                trailing: Group {
                    if canEditFood {
                        Menu {
                            Button {
                                showingAddToMealSheet = true
                            } label: {
                                Label("Öğüne Ekle", systemImage: "plus")
                            }
                            
                            Button {
                                showingEditSheet = true
                            } label: {
                                Label("Düzenle", systemImage: "pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        Button {
                            showingAddToMealSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            )
            .alert("Yiyeceği Sil", isPresented: $showingDeleteAlert) {
                Button("Sil", role: .destructive) {
                    deleteFood()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Bu yiyeceği silmek istediğinize emin misiniz?")
            }
            .sheet(isPresented: $showingEditSheet) {
                EditFoodView(food: food)
            }
            .sheet(isPresented: $showingAddToMealSheet) {
                AddToMealView(food: food)
            }
        }
    }
    
    private func deleteFood() {
        guard let foodId = food.id else {
            errorMessage = "Yiyecek ID'si bulunamadı"
            return
        }
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("foods")
                    .document(foodId)
                    .delete()
                dismiss()
            } catch {
                errorMessage = "Yiyecek silinirken hata oluştu: \(error.localizedDescription)"
            }
        }
    }
} 