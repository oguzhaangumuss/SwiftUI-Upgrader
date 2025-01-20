import SwiftUI
import FirebaseFirestore

struct MealsView: View {
    @StateObject private var viewModel = MealsViewModel()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tarih seçici
                DateSelectionHeader(
                    selectedDate: $selectedDate,
                    showingDatePicker: $showingDatePicker
                )
                
                // Öğün listesi
                List {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.meals.isEmpty {
                        EmptyStateView(
                            image: "fork.knife.circle",
                            message: "Bugün için öğün bulunmuyor"
                        )
                    } else {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            if let meals = viewModel.meals(for: mealType) {
                                Section(header: Text(mealType.rawValue)) {
                                    ForEach(meals) { meal in
                                        MealRow(meal: meal)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Günlük özet
                if !viewModel.meals.isEmpty {
                    let summary = viewModel.calculateDailySummary()
                    DailyNutritionSummary(summary: summary)
                }
            }
            .navigationTitle("Öğünlerim")
        }
        .onChange(of: selectedDate) { _ in
            Task {
                await viewModel.fetchMeals(for: selectedDate)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchMeals(for: selectedDate)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                DatePicker(
                    "Tarih Seç",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Tarih Seç")
                .navigationBarItems(
                    trailing: Button("Tamam") {
                        showingDatePicker = false
                    }
                )
            }
        }
    }
}

struct MealRow: View {
    let meal: UserMeal
    @StateObject private var foodsViewModel = FoodsViewModel.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.date.dateValue().formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(meal.foods, id: \.foodId) { mealFood in
                if let food = foodsViewModel.getFood(by: mealFood.foodId) {
                    HStack {
                        Text(food.name)
                        Spacer()
                        Text("\(Int(mealFood.portion))g")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DailyNutritionSummary: View {
    let summary: NutritionSummary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                NutritionValue(
                    title: "Kalori",
                    value: "\(summary.calories)",
                    unit: "kcal",
                    icon: "flame.fill"
                )
                
                NutritionValue(
                    title: "Protein",
                    value: String(format: "%.1f", summary.protein),
                    unit: "g",
                    icon: "p.circle.fill"
                )
                
                NutritionValue(
                    title: "Karb",
                    value: String(format: "%.1f", summary.carbs),
                    unit: "g",
                    icon: "c.circle.fill"
                )
                
                NutritionValue(
                    title: "Yağ",
                    value: String(format: "%.1f", summary.fat),
                    unit: "g",
                    icon: "f.circle.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct NutritionValue: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
