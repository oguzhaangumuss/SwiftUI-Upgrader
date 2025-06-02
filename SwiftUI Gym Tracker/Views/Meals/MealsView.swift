import SwiftUI
import FirebaseFirestore
import Charts

// Görüntüleme periyotlarını tanımlayan enum
enum ViewPeriod: String, CaseIterable, Identifiable {
    case daily = "Günlük"
    case weekly = "Haftalık"
    case monthly = "Aylık"
    
    var id: String { self.rawValue }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .daily:
            return .day
        case .weekly:
            return .weekOfYear
        case .monthly:
            return .month
        }
    }
}

enum MealPeriod: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case breakfast = "Kahvaltı"
    case lunch = "Öğle Yemeği"
    case dinner = "Akşam Yemeği"
    case snack = "Ara Öğün"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .all:
            return "Tümü"
        case .breakfast:
            return "Kahvaltı"
        case .lunch:
            return "Öğle"
        case .dinner:
            return "Akşam"
        case .snack:
            return "Ara"
        }
    }
    
    var mealTypeString: String {
        switch self {
        case .all:
            return ""
        case .breakfast:
            return "Kahvaltı"
        case .lunch:
            return "Öğle Yemeği"
        case .dinner:
            return "Akşam Yemeği"
        case .snack:
            return "Ara Öğün"
        }
    }
    
    static func fromMealTypeString(_ mealType: String) -> MealPeriod {
        switch mealType {
        case "Kahvaltı":
            return .breakfast
        case "Öğle Yemeği":
            return .lunch
        case "Akşam Yemeği":
            return .dinner
        case "Ara Öğün":
            return .snack
        default:
            return .all
        }
    }
}

struct MealsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var viewModel: MealsViewModel
    @EnvironmentObject var foodsViewModel: FoodsViewModel
    
    @State private var selectedDate = Date()
    @State private var selectedPeriod: ViewPeriod = .daily
    @State private var selectedMealPeriod: MealPeriod = .all
    @State private var showAddMeal = false
    
    var formatter: DateFormatter {
        let dateFormatter = DateFormatter()
        switch selectedPeriod {
        case .daily:
            dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        case .weekly:
            dateFormatter.dateFormat = "MMM d, yyyy"
        case .monthly:
            dateFormatter.dateFormat = "MMMM yyyy"
        }
        return dateFormatter
    }
    
    // Helper method to get meals filtered by period and date
    private func filteredMealsFor(period: ViewPeriod, date: Date, mealPeriod: MealPeriod) -> [SimpleMeal] {
        print("📊 DEBUG: filteredMealsFor çağrıldı - period: \(period), date: \(date), mealPeriod: \(mealPeriod)")
        
        // Get base meals for the selected time period
        let baseMeals: [SimpleMeal]
        switch period {
        case .daily:
            baseMeals = viewModel.getMealsForDay(date)
            print("📊 DEBUG: Daily view için \(baseMeals.count) öğün bulundu")
        case .weekly:
            baseMeals = viewModel.getMealsForWeek(containing: date)
            print("📊 DEBUG: Weekly view için \(baseMeals.count) öğün bulundu")
        case .monthly:
            baseMeals = viewModel.getMealsForMonth(containing: date)
            print("📊 DEBUG: Monthly view için \(baseMeals.count) öğün bulundu")
        }
        
        // Filter by meal type if needed
        if mealPeriod == .all {
            print("📊 DEBUG: Tüm öğün türleri gösteriliyor, filtre yok")
            return baseMeals
        } else {
            let filteredMeals = baseMeals.filter { $0.period == mealPeriod.mealTypeString }
            print("📊 DEBUG: \(mealPeriod.mealTypeString) için filtre uygulandı, \(filteredMeals.count) öğün bulundu")
            return filteredMeals
        }
    }
    
    // Simplified property using the helper method
    var mealsForPeriod: [SimpleMeal] {
        return filteredMealsFor(period: selectedPeriod, date: selectedDate, mealPeriod: selectedMealPeriod)
    }
    
    // Helper method to calculate nutrition from a meal array
    private func calculateTotalNutrition(from meals: [SimpleMeal]) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        
        for meal in meals {
            calories += meal.totalCalories
            protein += meal.totalProtein
            carbs += meal.totalCarbs
            fat += meal.totalFat
        }
        
        return (calories, protein, carbs, fat)
    }
    
    // Simplified property using the helper method
    var totalNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let meals = mealsForPeriod
        return calculateTotalNutrition(from: meals)
    }
    
    var noMealsMessage: String {
        switch selectedPeriod {
        case .daily:
            return "No meals found for \(formatter.string(from: selectedDate))"
        case .weekly:
            let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)!
            let endFormatter = DateFormatter()
            endFormatter.dateFormat = "MMM d"
            return "No meals found for week of \(formatter.string(from: startOfWeek)) - \(endFormatter.string(from: endOfWeek))"
        case .monthly:
            return "No meals found for \(formatter.string(from: selectedDate))"
        }
    }
    
    private func dailyMealsView() -> some View {
        // Use List for daily view to enable swipe-to-delete
        List {
            if mealsForPeriod.isEmpty {
                noMealsPlaceholder()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } else {
                mealItemsForEach()
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func mealItemsForEach() -> some View {
        // Önce yemekleri tipine göre grupla
        let groupedMeals = Dictionary(grouping: mealsForPeriod) { $0.period }
        
        // Her grup için tek bir kart oluştur
        return ForEach(groupedMeals.keys.sorted(), id: \.self) { mealType in
            if let meals = groupedMeals[mealType] {
                GroupedMealCard(
                    mealType: mealType,
                    meals: meals,
                    onDelete: { meal in
                        viewModel.deleteMeal(meal)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .background(Color.clear)
            } else {
                EmptyView() // Nil olması durumunda boş view döndür
            }
        }
    }
    
    private func otherPeriodsView() -> some View {
        // Use ScrollView for weekly and monthly views
        ScrollView {
            LazyVStack(spacing: 12) {
                if mealsForPeriod.isEmpty {
                    noMealsPlaceholder()
                } else {
                    // Önce yemekleri tipine göre grupla
                    let groupedMeals = Dictionary(grouping: mealsForPeriod) { $0.period }
                    
                    // Her grup için tek bir kart oluştur
                    ForEach(groupedMeals.keys.sorted(), id: \.self) { mealType in
                        if let meals = groupedMeals[mealType] {
                            GroupedMealCard(
                                mealType: mealType,
                                meals: meals,
                                onDelete: { meal in
                                    viewModel.deleteMeal(meal)
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // View Period Picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(ViewPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Date Navigation
                    HStack {
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: selectedPeriod.dateComponent, value: -1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(AppTheme.primaryColor)
                                .padding()
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(dateRangeText)
                                .font(.headline)
                            
                            if selectedPeriod != .daily {
                                Text(periodDetailText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedDate = Calendar.current.date(byAdding: selectedPeriod.dateComponent, value: 1, to: selectedDate) ?? selectedDate
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.primaryColor)
                                .padding()
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Today Button
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("Bugün")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryColor)
                            .cornerRadius(15)
                    }
                    .padding(.bottom, 8)
                    
                    // Meal Type Filter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MealPeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    selectedMealPeriod = period
                                }) {
                                    Text(period.title)
                                        .font(.subheadline)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(selectedMealPeriod == period ? AppTheme.primaryColor : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedMealPeriod == period ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Nutrition Summary
                    NutritionSummaryCard(
                        calories: totalNutrition.calories,
                        protein: totalNutrition.protein,
                        carbs: totalNutrition.carbs,
                        fat: totalNutrition.fat,
                        period: selectedPeriod
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Meals Display
                    if selectedPeriod == .daily {
                        dailyMealsView()
                    } else {
                        otherPeriodsView()
                    }
                }
            }
            .navigationTitle("Öğünler")
            .navigationBarItems(
                trailing: Button(action: {
                    showAddMeal = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.primaryColor)
                        .imageScale(.large)
                }
            )
            .sheet(isPresented: $showAddMeal) {
                AddMealView(showSheet: $showAddMeal, selectedDate: $selectedDate)
            }
            .navigationBarTitle(
                selectedPeriod == .daily ? "Günlük Öğünler" :
                selectedPeriod == .weekly ? "Haftalık Öğünler" : "Aylık Öğünler",
                displayMode: .inline
            )
            .onAppear {
                print("📊 DEBUG: MealsView onAppear - tarih: \(selectedDate), period: \(selectedPeriod), mealPeriod: \(selectedMealPeriod)")
                foodsViewModel.fetchFoods()
                fetchMealsForSelectedPeriod()
        }
        .onChange(of: selectedDate) { _ in
                print("📊 DEBUG: selectedDate değişti: \(selectedDate)")
                fetchMealsForSelectedPeriod()
            }
            .onChange(of: selectedPeriod) { _ in
                print("📊 DEBUG: selectedPeriod değişti: \(selectedPeriod)")
                fetchMealsForSelectedPeriod()
            }
            .onChange(of: selectedMealPeriod) { _ in
                print("📊 DEBUG: selectedMealPeriod değişti: \(selectedMealPeriod)")
                // Sadece UI filtrelemesi, veri çekmeye gerek yok
            }
        }
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .daily:
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: selectedDate)
            
        case .weekly:
            formatter.dateFormat = "d MMMM"
            
            guard let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) else {
                return ""
            }
            
            guard let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) else {
                return ""
            }
            
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            
            return "\(startString) - \(endString)"
            
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        }
    }
    
    private var periodDetailText: String {
        switch selectedPeriod {
        case .weekly:
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekOfYear], from: selectedDate)
            if let weekNumber = components.weekOfYear {
                return "\(weekNumber). Hafta"
            }
            return ""
            
        case .monthly:
            return ""
            
        default:
            return ""
        }
    }
    
    private func noMealsPlaceholder() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.primaryColor.opacity(0.5))
            
            Text(noMealsMessage)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showAddMeal = true
            }) {
                Text("Öğün Ekle")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // Add helper method to fetch meals based on selected period
    private func fetchMealsForSelectedPeriod() {
        print("📊 DEBUG: fetchMealsForSelectedPeriod çağrıldı")
        switch selectedPeriod {
        case .daily:
            print("📊 DEBUG: Günlük öğünler çekiliyor...")
            viewModel.fetchDailyMeals(for: selectedDate)
        case .weekly:
            print("📊 DEBUG: Haftalık öğünler çekiliyor...")
            viewModel.fetchWeeklyMeals(for: selectedDate)
        case .monthly:
            print("📊 DEBUG: Aylık öğünler çekiliyor...")
            viewModel.fetchMonthlyMeals(for: selectedDate)
        }
    }
}

// MARK: - NutritionSummaryCard

struct NutritionSummaryCard: View {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var period: ViewPeriod
    
    var body: some View {
        VStack(spacing: 12) {
            Text(summarizeTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                NutritionItem(
                    title: "Kalori",
                    value: "\(Int(calories)) kcal",
                    color: .orange
                )
                
                Divider()
                
                NutritionItem(
                    title: "Protein",
                    value: "\(Int(protein)) g",
                    color: .blue
                )
                
                Divider()
                
                NutritionItem(
                    title: "Karb",
                    value: "\(Int(carbs)) g",
                    color: .green
                )
                
                Divider()
                
                NutritionItem(
                    title: "Yağ",
                    value: "\(Int(fat)) g",
                    color: .red
                )
            }
            
            // Nutrition Ratio Chart
            if calories > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(protein * 4 / calories))
                        
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(carbs * 4 / calories))
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geometry.size.width * CGFloat(fat * 9 / calories))
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                }
                .frame(height: 8)
                
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("Protein")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Karb")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Yağ")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    var summarizeTitle: String {
        switch period {
        case .daily:
            return "Günlük Beslenme Özeti"
        case .weekly:
            return "Haftalık Beslenme Özeti"
        case .monthly:
            return "Aylık Beslenme Özeti"
        }
    }
}

// MARK: - MealCard

struct MealCard: View {
    var meal: SimpleMeal
    var showFoods: Bool = true
    var onDelete: (() -> Void)? = nil
    @State private var showFoodList: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Meal Header
            HStack {
                // Convert the string period to a MealPeriod enum using fromMealTypeString
                let mealPeriod = MealPeriod.fromMealTypeString(meal.period)
                Image(systemName: mealIcon(for: mealPeriod))
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primaryColor)
                
                VStack(alignment: .leading) {
                    Text(meal.period)
                        .font(.headline)
                    
                    Text(formattedTime(from: meal.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(meal.totalCalories)) kcal")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                if onDelete != nil {
                    Button(action: {
                        onDelete?()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(AppTheme.primaryColor)
                            .font(.system(size: 16))
                            .padding(8)
                    }
                }
            }
            
            // Meal Nutrition Summary
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Text("P:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.totalProtein))g")
                        .font(.caption)
                        .bold()
                }
                
                HStack(spacing: 4) {
                    Text("K:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.totalCarbs))g")
                        .font(.caption)
                        .bold()
                }
                
                HStack(spacing: 4) {
                    Text("Y:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(meal.totalFat))g")
                        .font(.caption)
                        .bold()
                }
                
                Spacer()
                
                if showFoods && !meal.foods.isEmpty {
                    Button(action: {
                        showFoodList.toggle()
                    }) {
                        Image(systemName: showFoodList ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // Food List (only shown for daily view)
            if showFoods && showFoodList && !meal.foods.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(meal.foods) { food in
                        HStack {
                            Text(food.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(Int(food.quantity))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(food.calories)) kcal")
                                .font(.caption)
                                .bold()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func mealIcon(for period: MealPeriod) -> String {
        switch period {
        case .breakfast:
            return "sunrise"
        case .lunch:
            return "sun.max"
        case .dinner:
            return "sunset"
        case .snack:
            return "fork.knife"
        case .all:
            return "calendar"
        }
    }
    
    // Helper method to format time
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - GroupedMealCard

struct GroupedMealCard: View {
    var mealType: String
    var meals: [SimpleMeal]
    var onDelete: ((SimpleMeal) -> Void)? = nil
    @State private var showFoodList: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Meal Header
            HStack {
                let mealPeriod = MealPeriod.fromMealTypeString(mealType)
                Image(systemName: mealIcon(for: mealPeriod))
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primaryColor)
                
                VStack(alignment: .leading) {
                    Text(mealType)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(totalCalories)) kcal")
                .font(.headline)
                        .foregroundColor(.orange)
                }
                
                Button(action: {
                    showFoodList.toggle()
                }) {
                    Image(systemName: showFoodList ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(8)
                }
            }
            
            // Toplam besin değerleri
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Text("P:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalProtein))g")
                        .font(.caption)
                        .bold()
                }
                
                HStack(spacing: 4) {
                    Text("K:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalCarbs))g")
                        .font(.caption)
                        .bold()
                }
                
                HStack(spacing: 4) {
                    Text("Y:")
                .font(.caption2)
                .foregroundColor(.secondary)
                    Text("\(Int(totalFat))g")
                        .font(.caption)
                        .bold()
                }
                
                Spacer()
            }
            
            // Tüm yemeklerin listesi
            if showFoodList {
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(meals, id: \.id) { meal in
                    VStack(alignment: .leading, spacing: 6) {
                        // Yemek saati
                        HStack {
                            Text(formattedTime(from: meal.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(meal.totalCalories)) kcal")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            if onDelete != nil {
                                Button(action: {
                                    onDelete?(meal)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(AppTheme.primaryColor)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        
                        // Yiyecek listesi
                        if !meal.foods.isEmpty {
                            ForEach(meal.foods) { food in
                                HStack {
                                    Text("• \(food.name)")
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(food.quantity))g")
                .font(.caption)
                .foregroundColor(.secondary)
                                    
                                    Text("\(Int(food.calories)) kcal")
                                        .font(.caption)
                                        .bold()
                                }
                                .padding(.leading, 10)
                            }
                        }
                    }
                    
                    if meal.id != meals.last?.id {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Toplam kalori hesapla
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.totalCalories }
    }
    
    // Toplam protein hesapla
    var totalProtein: Double {
        meals.reduce(0) { $0 + $1.totalProtein }
    }
    
    // Toplam karbonhidrat hesapla
    var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.totalCarbs }
    }
    
    // Toplam yağ hesapla
    var totalFat: Double {
        meals.reduce(0) { $0 + $1.totalFat }
    }
    
    // Zaman formatla
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func mealIcon(for period: MealPeriod) -> String {
        switch period {
        case .breakfast:
            return "sunrise"
        case .lunch:
            return "sun.max"
        case .dinner:
            return "sunset"
        case .snack:
            return "fork.knife"
        case .all:
            return "calendar"
        }
    }
}

// MARK: - Preview

struct MealsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MealsView()
                .environmentObject(AppSettings())
                .environmentObject(MealsViewModel.shared)
                .environmentObject(FoodsViewModel.shared) 
        }
    }
}

