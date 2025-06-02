import SwiftUI
import FirebaseFirestore

struct FoodsView: View {
    @StateObject private var viewModel = FoodsViewModel.shared
    @State private var searchText = ""
    @State private var showingAddFoodSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            searchHeader
                            
                            categoryScrollView
                            
                            if searchText.isEmpty && viewModel.selectedCategory == nil {
                                featuredFoodsSection
                            }
                            
                            foodsGridView
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Yiyecekler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFoodSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFoodSheet) {
                AddFoodView()
            }
            .onAppear {
                viewModel.fetchFoods()
            }
        }
    }
    
    // MARK: - Search Header
    private var searchHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Yiyecek ara...", text: $searchText)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.top, 10)
    }
    
    // MARK: - Category Scroll View
    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    title: "Hepsi",
                    icon: "square.grid.2x2",
                    color: Color(red: 0.2, green: 0.5, blue: 0.9),
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }
                
                ForEach(Food.Category.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.title,
                        icon: category.icon,
                        color: category.color,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Featured Foods Section
    private var featuredFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("High in Protein")
                .font(.headline)
                .padding(.top, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    let proteinRichFoods = viewModel.foods
                        .sorted(by: { $0.protein > $1.protein })
                        .prefix(5)
                    
                    ForEach(proteinRichFoods) { food in
                        FoodCard(food: food)
                    }
                }
            }
        }
    }
    
    // MARK: - Foods Grid View
    private var foodsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            let filteredFoods = viewModel.filteredFoods.filter {
                searchText.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(searchText)
            }
            
            if filteredFoods.isEmpty {
                Text("No foods found")
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                    .gridCellColumns(2)
            } else {
                ForEach(filteredFoods) { food in
                    FoodCompactCard(food: food)
                }
            }
        }
        .padding(.top, 10)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.5))
            .cornerRadius(25)
        }
    }
}

// MARK: - Food Card Views
struct FoodCard: View {
    let food: Food
    
    var body: some View {
        NavigationLink(destination: FoodDetailView(food: food)) {
            ZStack(alignment: .bottom) {
                if let imageUrl = food.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .transition(.opacity)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 160, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Rectangle()
                        .foregroundColor(food.foodCategory.color.opacity(0.3))
                        .frame(width: 160, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Image(systemName: food.foodCategory.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if !food.brand.isEmpty {
                        Text(food.brand)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        NutrientBadge(value: Int(food.calories), unit: "kcal", color: .orange)
                        NutrientBadge(value: Int(food.protein), unit: "P", color: .red)
                    }
                }
                .padding(10)
                .frame(width: 160, alignment: .leading)
                .background(LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                    startPoint: .bottom,
                    endPoint: .top
                ))
                .cornerRadius(12)
            }
            .frame(width: 160, height: 180)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        }
    }
}

struct FoodCompactCard: View {
    let food: Food
    
    var body: some View {
        NavigationLink(destination: FoodDetailView(food: food)) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                
                VStack(spacing: 10) {
                    ZStack {
                        if let imageUrl = food.imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray.opacity(0.3)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                        } else {
                            Rectangle()
                                .foregroundColor(food.foodCategory.color.opacity(0.3))
                                .frame(height: 100)
                                .overlay(
                                    Image(systemName: food.foodCategory.icon)
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(height: 100)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(food.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if !food.brand.isEmpty {
                            Text(food.brand)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            NutrientBadge(value: Int(food.calories), unit: "kcal", color: .orange)
                            Spacer()
                            NutrientBadge(value: Int(food.protein), unit: "P", color: .red)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
            .frame(height: 180)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct NutrientBadge: View {
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(6)
    }
}

// MARK: - Preview
struct FoodsView_Previews: PreviewProvider {
    static var previews: some View {
        FoodsView()
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
