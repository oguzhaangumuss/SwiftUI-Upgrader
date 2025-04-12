import SwiftUI
import FirebaseFirestore

// Görüntüleme periyotlarını tanımlayan enum
enum MealPeriod: String, CaseIterable {
    case daily = "Günlük"
    case weekly = "Haftalık"
    case monthly = "Aylık"
}

struct MealsView: View {
    @StateObject private var viewModel = MealsViewModel()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var selectedPeriod: MealPeriod = .daily
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tarih seçici
                DateSelectionHeader(
                    selectedDate: $selectedDate,
                    showingDatePicker: $showingDatePicker
                )
                
                // Periyot seçimi için segmented control
                Picker("Periyot", selection: $selectedPeriod) {
                    ForEach(MealPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Öğün listesi
                List {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.meals.isEmpty {
                        EmptyStateView(
                            image: "fork.knife.circle",
                            message: selectedPeriod == .daily ? "Bugün için öğün bulunmuyor" : "Bu periyotta öğün bulunmuyor"
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
                
                // Periyota göre özet
                if !viewModel.meals.isEmpty {
                    let summary = viewModel.calculateDailySummary()
                    DailyNutritionSummary(summary: summary)
                }
            }
            .navigationTitle(navigationTitle)
        }
        .onChange(of: selectedDate) { _ in
            fetchMealsForSelectedPeriod()
        }
        .onChange(of: selectedPeriod) { _ in
            fetchMealsForSelectedPeriod()
        }
        .onAppear {
            fetchMealsForSelectedPeriod()
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
    
    // Seçilen periyota göre başlık belirleme
    private var navigationTitle: String {
        switch selectedPeriod {
        case .daily:
            return "Günlük Öğünlerim"
        case .weekly:
            return "Haftalık Öğünlerim"
        case .monthly:
            return "Aylık Öğünlerim"
        }
    }
    
    // Seçilen periyota göre veri çekme
    private func fetchMealsForSelectedPeriod() {
        Task {
            switch selectedPeriod {
            case .daily:
                await viewModel.fetchMeals(for: selectedDate)
            case .weekly:
                await viewModel.fetchMealsForWeek(startDate: getWeekStartDate())
            case .monthly:
                await viewModel.fetchMealsForMonth(startDate: getMonthStartDate())
            }
        }
    }
    
    // Haftanın başlangıç tarihini hesaplama
    private func getWeekStartDate() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
    }
    
    // Ayın başlangıç tarihini hesaplama
    private func getMonthStartDate() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        return calendar.date(from: components) ?? selectedDate
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
