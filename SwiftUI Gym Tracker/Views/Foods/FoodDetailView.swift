import SwiftUI
import FirebaseFirestore

struct FoodDetailView: View {
    let food: Food
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddToMealSheet = false
    @State private var errorMessage = ""
    @State private var imageLoadError = false
    
    private var canEditFood: Bool {
        let currentUserId = FirebaseManager.shared.auth.currentUser?.uid
        return food.createdBy == currentUserId || FirebaseManager.shared.currentUser?.isAdmin == true
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image
                ZStack(alignment: .bottom) {
                    if let imageUrl = food.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .foregroundColor(Color(.systemGray5))
                                    .frame(height: 250)
                                    .overlay {
                                        ProgressView()
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .foregroundColor(Color(.systemGray5))
                                    .frame(height: 250)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                            Text("Image could not be loaded")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                    .onAppear { imageLoadError = true }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Rectangle()
                            .foregroundColor(food.foodCategory.color.opacity(0.3))
                            .frame(height: 250)
                            .overlay {
                                Image(systemName: food.foodCategory.icon)
                                    .font(.system(size: 60))
                                    .foregroundColor(food.foodCategory.color)
                            }
                    }
                    
                    // Food info overlay
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(food.foodCategory.title)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(food.foodCategory.color.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            if !food.brand.isEmpty {
                                Text(food.brand)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.7))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
                
                // Content
                VStack(spacing: 24) {
                    // Nutrition summary cards
                    HStack(spacing: 12) {
                        NutritionCard(value: Int(food.calories), unit: "kcal", title: "Calories", color: .orange)
                        NutritionCard(value: Int(food.protein), unit: "g", title: "Protein", color: .red)
                        NutritionCard(value: Int(food.carbs), unit: "g", title: "Carbs", color: .blue)
                        NutritionCard(value: Int(food.fat), unit: "g", title: "Fat", color: .green)
                    }
                    .padding(.top, 24)
                    
                    // Detailed nutrient information
                    VStack(spacing: 16) {
                        DetailedNutrientRow(name: "Calories", value: "\(Int(food.calories))", unit: "kcal", iconName: "flame.fill", color: .orange)
                        DetailedNutrientRow(name: "Protein", value: String(format: "%.1f", food.protein), unit: "g", iconName: "staroflife.fill", color: .red)
                        DetailedNutrientRow(name: "Carbohydrates", value: String(format: "%.1f", food.carbs), unit: "g", iconName: "leaf.fill", color: .blue)
                        DetailedNutrientRow(name: "Fat", value: String(format: "%.1f", food.fat), unit: "g", iconName: "drop.fill", color: .green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            showingAddToMealSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Meal")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if canEditFood {
                            HStack(spacing: 12) {
                                Button {
                                    showingEditSheet = true
                                } label: {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                                }
                                
                                Button {
                                    showingDeleteAlert = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Food", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteFood()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this food?")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditFoodView(food: food)
        }
        .sheet(isPresented: $showingAddToMealSheet) {
            AddToMealView(food: food)
        }
        .overlay {
            if !errorMessage.isEmpty {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: errorMessage)
            }
        }
    }
    
    private func deleteFood() {
        guard let foodId = food.id else {
            errorMessage = "Food ID not found"
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
                errorMessage = "Error deleting food: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Supporting Views
struct NutritionCard: View {
    let value: Int
    let unit: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(color.opacity(0.8))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailedNutrientRow: View {
    let name: String
    let value: String
    let unit: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(name)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview
struct FoodDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FoodDetailView(food: Food(
                id: "1",
                name: "Example Food",
                brand: "Brand Name",
                calories: 250,
                protein: 15,
                carbs: 30,
                fat: 8,
                imageUrl: nil,
                createdBy: "",
                createdAt: Timestamp(),
                updatedAt: Timestamp(),
                category: "Protein Kaynakları"
            ))
        }
    }
} 