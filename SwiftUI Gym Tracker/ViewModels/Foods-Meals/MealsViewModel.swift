import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation


class MealsViewModel: ObservableObject {
    // Add shared singleton instance
    static let shared = MealsViewModel()
    
    @Published var dailyMeals: [SimpleMeal] = []
    @Published var weeklyMeals: [DailySummary] = []
    @Published var monthlyMeals: [DailySummary] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var errorMessage: String = ""
    
    private let db = FirebaseManager.shared.firestore
    private let foodsViewModel = FoodsViewModel.shared
    private let userId = Auth.auth().currentUser?.uid ?? ""
    private var meals: [UserMeal] = []
    
    // Calendar instance for date calculations
    private let calendar = Calendar.current
    
    // Renamed the computed property to formattedMeals to avoid conflict
    var formattedMeals: [SimpleMeal] {
        print("📊 DEBUG: formattedMeals getter çağrıldı - meals.count: \(meals.count)")
        let result = meals.flatMap { userMeal in
            // Önce meals içindeki her bir food için SimpleFoodItem oluştur
            let foodItems = userMeal.foods.compactMap { mealFood -> SimpleFoodItem? in
                guard let food = foodsViewModel.getFood(by: mealFood.foodId) else {
                    print("⚠️ WARNING: \(mealFood.foodId) ID'li yiyecek bulunamadı")
                    return nil
                }
                let portionMultiplier = mealFood.portion / 100.0
                
                return SimpleFoodItem(
                    id: mealFood.foodId,
                    name: food.name,
                    quantity: mealFood.portion,
                    calories: food.calories * portionMultiplier,
                    protein: food.protein * portionMultiplier,
                    carbs: food.carbs * portionMultiplier,
                    fat: food.fat * portionMultiplier
                )
            }
            
            // Her bir userMeal için bir SimpleMeal oluştur ve foods dizisini doldur
            return [SimpleMeal(
                id: userMeal.id ?? UUID().uuidString,
                name: userMeal.mealType.rawValue,
                quantity: 0,
                calories: foodItems.reduce(0) { $0 + $1.calories },
                protein: foodItems.reduce(0) { $0 + ($1.protein ?? 0) },
                carbs: foodItems.reduce(0) { $0 + ($1.carbs ?? 0) },
                fat: foodItems.reduce(0) { $0 + ($1.fat ?? 0) },
                period: userMeal.mealType.rawValue,
                note: nil,
                foodId: "",
                createdAt: userMeal.createdAt.dateValue(),
                foods: foodItems
            )]
        }
        print("📊 DEBUG: formattedMeals sonucu - \(result.count) öğün")
        if !result.isEmpty {
            print("📊 DEBUG: İlk öğün: id=\(result[0].id), period=\(result[0].period), tarih=\(result[0].createdAt)")
        }
        return result
    }
    
    // Add the missing fetchDailyMeals method
    func fetchDailyMeals(for date: Date) {
        Task {
            await fetchMeals(for: date)
        }
    }
    
    @MainActor
    func fetchMeals(for date: Date) async {
        print("📊 DEBUG: fetchMeals çağrıldı - date: \(date)")
        
        await MainActor.run {
            isLoading = true
            meals = []
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        print("📊 DEBUG: Günlük öğünler çekiliyor - \(startOfDay) ile \(endOfDay) arasında")
        await fetchMealsBetween(start: startOfDay, end: endOfDay)
    }
    
    @MainActor
    func fetchMealsForWeek(startDate: Date) async {
        await MainActor.run {
            isLoading = true
            weeklyMeals = []
        }
        
        let calendar = Calendar.current
        
        // Haftanın başlangıç ve bitiş günlerini belirle
        // Pazartesi-Pazar formatlı hafta için (haftanın ilk günü = 2 [Pazartesi])
        var component = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        let startOfWeek = calendar.date(from: component)!
        
        // Haftanın son günü (Pazar) = başlangıç (Pazartesi) + 6 gün
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        print("📊 DEBUG: Haftalık sorgulama - Başlangıç: \(startOfWeek), Bitiş: \(endOfWeek)")
        
        do {
            let snapshot = try await db
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfWeek))
                .whereField("date", isLessThan: Timestamp(date: endOfWeek))
                .getDocuments()
            
            let fetchedMeals = snapshot.documents.compactMap { document -> UserMeal? in
                try? document.data(as: UserMeal.self)
            }
            
            print("📊 DEBUG: Haftalık veri: \(fetchedMeals.count) öğün bulundu")
            print("📊 DEBUG: Tarih aralığı: \(startOfWeek) - \(endOfWeek)")
            
            // Yemekleri günlere göre grupla
            let groupedByDay = Dictionary(grouping: fetchedMeals) { meal in
                calendar.startOfDay(for: meal.date.dateValue())
            }
            
            // Her gün için DailySummary oluştur
            for (day, mealsForDay) in groupedByDay {
                var mealsByType: [MealPeriod: SimpleMeal] = [:]
                var totalCalories: Double = 0
                
                // Yemekleri türlerine göre grupla
                let groupedByType = Dictionary(grouping: mealsForDay) { $0.mealType }
                
                for (mealType, mealsOfType) in groupedByType {
                    // Toplam değerleri hesapla
                    var totalProtein: Double = 0
                    var totalCarbs: Double = 0
                    var totalFat: Double = 0
                    var calories: Double = 0
                    var foodItems: [SimpleFoodItem] = []
                    
                    for meal in mealsOfType {
                        for food in meal.foods {
                            if let foodData = foodsViewModel.getFood(by: food.foodId) {
                                let portionMultiplier = food.portion / 100.0
                                
                                let foodCalories = foodData.calories * portionMultiplier
                                calories += foodCalories
                                totalProtein += foodData.protein * portionMultiplier
                                totalCarbs += foodData.carbs * portionMultiplier
                                totalFat += foodData.fat * portionMultiplier
                                
                                foodItems.append(SimpleFoodItem(
                                    id: food.foodId,
                                    name: foodData.name,
                                    quantity: food.portion,
                                    calories: foodCalories,
                                    protein: foodData.protein * portionMultiplier,
                                    carbs: foodData.carbs * portionMultiplier,
                                    fat: foodData.fat * portionMultiplier
                                ))
                            }
                        }
                    }
                    
                    totalCalories += calories
                    
                    // Bu tür için özet yemek oluştur
                    if let typePeriod = MealPeriod(rawValue: mealType.rawValue) {
                        mealsByType[typePeriod] = SimpleMeal(
                            id: UUID().uuidString,
                            name: mealType.rawValue,
                            quantity: 0,
                            calories: calories,
                            protein: totalProtein,
                            carbs: totalCarbs,
                            fat: totalFat,
                            period: mealType.rawValue,
                            note: nil,
                            foodId: "",
                            createdAt: day,
                            foods: foodItems
                        )
                    }
                }
                
                // Eğer bu gün için yemek varsa, haftalık özetlere ekle
                if !mealsByType.isEmpty {
                    self.weeklyMeals.append(DailySummary(
                        date: day,
                        totalCalories: totalCalories,
                        mealsByType: mealsByType
                    ))
                }
            }
            
            // Haftalık özetleri tarihe göre sırala
            self.weeklyMeals.sort { $0.date < $1.date }
            self.isLoading = false
            
        } catch {
            print("Error fetching weekly meals: \(error)")
            self.isLoading = false
        }
    }
    
    @MainActor
    func fetchMealsForMonth(startDate: Date) async {
        await MainActor.run {
            isLoading = true
            monthlyMeals = []
        }
        
        let calendar = Calendar.current
        
        // Ayın başlangıcını bul
        var components = calendar.dateComponents([.year, .month], from: startDate)
        components.day = 1
        let startOfMonth = calendar.date(from: components)!
        
        // Ay sonunu bul
        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        nextMonthComponents.day = 0
        let endOfMonth = calendar.date(byAdding: nextMonthComponents, to: startOfMonth)!
        
        print("📊 DEBUG: Aylık sorgulama - Başlangıç: \(startOfMonth), Bitiş: \(endOfMonth)")
        
        // Tüm ay için tek sorgu yap
        do {
            let snapshot = try await db
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
                .whereField("date", isLessThan: Timestamp(date: endOfMonth))
                .getDocuments()
            
            let fetchedMeals = snapshot.documents.compactMap { document -> UserMeal? in
                try? document.data(as: UserMeal.self)
            }
            
            print("📊 DEBUG: Aylık veri: \(fetchedMeals.count) öğün bulundu")
            print("📊 DEBUG: Tarih aralığı: \(startOfMonth) - \(endOfMonth)")
            
            // Yemekleri günlere göre grupla
            let groupedByDay = Dictionary(grouping: fetchedMeals) { meal in
                calendar.startOfDay(for: meal.date.dateValue())
            }
            
            // Her gün için DailySummary oluştur
            for (day, mealsForDay) in groupedByDay {
                var mealsByType: [MealPeriod: SimpleMeal] = [:]
                var totalCalories: Double = 0
                
                // Yemekleri türlerine göre grupla
                let groupedByType = Dictionary(grouping: mealsForDay) { $0.mealType }
                
                for (mealType, mealsOfType) in groupedByType {
                    // Toplam değerleri hesapla
                    var totalProtein: Double = 0
                    var totalCarbs: Double = 0
                    var totalFat: Double = 0
                    var calories: Double = 0
                    var foodItems: [SimpleFoodItem] = []
                    
                    for meal in mealsOfType {
                        for food in meal.foods {
                            if let foodData = foodsViewModel.getFood(by: food.foodId) {
                                let portionMultiplier = food.portion / 100.0
                                
                                let foodCalories = foodData.calories * portionMultiplier
                                calories += foodCalories
                                totalProtein += foodData.protein * portionMultiplier
                                totalCarbs += foodData.carbs * portionMultiplier
                                totalFat += foodData.fat * portionMultiplier
                                
                                foodItems.append(SimpleFoodItem(
                                    id: food.foodId,
                                    name: foodData.name,
                                    quantity: food.portion,
                                    calories: foodCalories,
                                    protein: foodData.protein * portionMultiplier,
                                    carbs: foodData.carbs * portionMultiplier,
                                    fat: foodData.fat * portionMultiplier
                                ))
                            }
                        }
                    }
                    
                    totalCalories += calories
                    
                    // Bu tür için özet yemek oluştur
                    if let typePeriod = MealPeriod(rawValue: mealType.rawValue) {
                        mealsByType[typePeriod] = SimpleMeal(
                            id: UUID().uuidString,
                            name: mealType.rawValue,
                            quantity: 0,
                            calories: calories,
                            protein: totalProtein,
                            carbs: totalCarbs,
                            fat: totalFat,
                            period: mealType.rawValue,
                            note: nil,
                            foodId: "",
                            createdAt: day,
                            foods: foodItems
                        )
                    }
                }
                
                // Eğer bu gün için yemek varsa, aylık özetlere ekle
                if !mealsByType.isEmpty {
                    self.monthlyMeals.append(DailySummary(
                        date: day,
                        totalCalories: totalCalories,
                        mealsByType: mealsByType
                    ))
                }
            }
            
            // Aylık özetleri tarihe göre sırala
            self.monthlyMeals.sort { $0.date < $1.date }
            self.isLoading = false
            
        } catch {
            print("Error fetching monthly meals: \(error)")
            self.isLoading = false
        }
    }
    
    private func fetchMealsBetween(start: Date, end: Date) async {
        guard !userId.isEmpty else {
            print("❌ ERROR: userId boş, veri çekilemiyor!")
            return
        }
        
        print("📊 DEBUG: fetchMealsBetween çağrıldı - start: \(start), end: \(end), userId: \(userId)")
        
        do {
            let snapshot = try await FirebaseManager.shared.firestore
                .collection("userMeals")
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
                .whereField("date", isLessThan: Timestamp(date: end))
                .getDocuments()
            
            let fetchedMeals = snapshot.documents.compactMap { document -> UserMeal? in
                print("📊 DEBUG: Belge ID: \(document.documentID)")
                return try? document.data(as: UserMeal.self)
            }
            
            print("📊 DEBUG: Günlük veri: \(fetchedMeals.count) öğün bulundu")
            print("📊 DEBUG: Öğün IDs: \(fetchedMeals.map { $0.id ?? "nil" })")
            
            // Detaylı öğün içeriği
            for (index, meal) in fetchedMeals.enumerated() {
                print("📊 DEBUG: Öğün #\(index + 1):")
                print("   - ID: \(meal.id ?? "nil")")
                print("   - Tür: \(meal.mealType.rawValue)")
                print("   - Tarih: \(meal.date.dateValue())")
                print("   - Yiyecek sayısı: \(meal.foods.count)")
            }
            
            await MainActor.run {
                self.meals = fetchedMeals.sorted(by: { $0.date.dateValue() < $1.date.dateValue() })
                print("📊 DEBUG: meals dizisine \(self.meals.count) öğün eklendi")
                print("📊 DEBUG: formattedMeals dizisinde \(self.formattedMeals.count) öğün var")
                isLoading = false
            }
            
        } catch {
            print("❌ ERROR: Öğünler çekilirken hata: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func meals(for type: MealType) -> [UserMeal]? {
        let mealsForType = meals.filter { $0.mealType == type }
        return mealsForType.isEmpty ? nil : mealsForType
    }
    
    func calculateDailySummary() -> NutritionSummary {
        var summary = NutritionSummary()
        
        for meal in meals {
            for mealFood in meal.foods {
                if let food = foodsViewModel.getFood(by: mealFood.foodId) {
                    let portionMultiplier = mealFood.portion / 100.0
                    
                    let calculatedCalories = Double(food.calories) * portionMultiplier
                    summary.calories += calculatedCalories
                    summary.protein += food.protein * portionMultiplier
                    summary.carbs += food.carbs * portionMultiplier
                    summary.fat += food.fat * portionMultiplier
                }
            }
        }
        
        return summary
    }
    
    // Function to get a food by ID
    func getFood(by id: String) -> Food? {
        return foodsViewModel.getFood(by: id)
    }
    
    // MARK: - Fetching Methods
    
    func fetchWeeklyMeals(for date: Date) {
        Task {
            await fetchMealsForWeek(startDate: date)
        }
    }
    
    func fetchMonthlyMeals(for date: Date) {
        Task {
            await fetchMealsForMonth(startDate: date)
        }
    }
    
    // Calculate nutrition summary for a specific date
    func calculateDailyNutritionSummary(for date: Date) -> NutritionSummary {
        let meals = formattedMeals
        
        return NutritionSummary(
            calories: meals.reduce(0) { $0 + $1.totalCalories },
            protein: meals.reduce(0) { $0 + $1.totalProtein },
            carbs: meals.reduce(0) { $0 + $1.totalCarbs },
            fat: meals.reduce(0) { $0 + $1.totalFat }
        )
    }
    
    // Calculate nutrition summary for a week
    func calculateWeeklyNutritionSummary(for date: Date) -> NutritionSummary {
        let summary = weeklyMeals.reduce(NutritionSummary()) { result, dailySummary in
            var newResult = result
            
            dailySummary.mealsByType.values.forEach { meal in
                newResult.calories += meal.totalCalories
                newResult.protein += meal.totalProtein
                newResult.carbs += meal.totalCarbs
                newResult.fat += meal.totalFat
            }
            
            return newResult
        }
        
        return summary
    }
    
    // Calculate nutrition summary for a month
    func calculateMonthlyNutritionSummary(for date: Date) -> NutritionSummary {
        let summary = monthlyMeals.reduce(NutritionSummary()) { result, dailySummary in
            var newResult = result
            
            dailySummary.mealsByType.values.forEach { meal in
                newResult.calories += meal.totalCalories
                newResult.protein += meal.totalProtein
                newResult.carbs += meal.totalCarbs
                newResult.fat += meal.totalFat
            }
            
            return newResult
        }
        
        return summary
    }
    
    // Get meals for a specific day
    func getMealsForDay(_ date: Date) -> [SimpleMeal] {
        print("📊 DEBUG: getMealsForDay çağrıldı - date: \(date)")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let result = formattedMeals.filter { meal in
            meal.createdAt >= startOfDay && meal.createdAt < endOfDay
        }
        
        print("📊 DEBUG: getMealsForDay sonucu: \(result.count) öğün bulundu")
        if result.isEmpty {
            print("📊 DEBUG: Günlük öğün bulunamadı! Tarih aralığı: \(startOfDay) - \(endOfDay)")
            print("📊 DEBUG: formattedMeals.count: \(formattedMeals.count)")
            if !formattedMeals.isEmpty {
                print("📊 DEBUG: İlk öğün tarihi: \(formattedMeals[0].createdAt)")
                print("📊 DEBUG: Son öğün tarihi: \(formattedMeals.last!.createdAt)")
            }
        }
        
        return result
    }
    
    // Get meals for the week containing the specified date
    func getMealsForWeek(containing date: Date) -> [SimpleMeal] {
        let calendar = Calendar.current
        let weekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let startOfWeek = calendar.date(from: weekComponents) else { return [] }
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return [] }
        
        return formattedMeals.filter { meal in
            meal.createdAt >= startOfWeek && meal.createdAt < endOfWeek
        }
    }
    
    // Get meals for the month containing the specified date
    func getMealsForMonth(containing date: Date) -> [SimpleMeal] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }
        
        return formattedMeals.filter { meal in
            meal.createdAt >= startOfMonth && meal.createdAt < nextMonth
        }
    }
    
    // Delete a meal from Firestore by its ID
    private func deleteMealFromFirestore(_ mealId: String) async throws {
        try await db.collection("userMeals").document(mealId).delete()
    }
    
    // Update deleteMeal to accept a SimpleMeal object
    func deleteMeal(_ meal: SimpleMeal) {
        Task {
            do {
                // Find the original UserMeal that corresponds to this SimpleMeal
                if let userMeal = meals.first(where: { $0.id == meal.id }),
                   let mealId = userMeal.id {
                    try await deleteMealFromFirestore(mealId)
                    
                    // Update the UI on the main thread
                    await MainActor.run {
                        // Remove the meal from our array
                        self.meals.removeAll(where: { $0.id == meal.id })
                        // formattedMeals is a computed property that depends on meals, 
                        // so we don't need to modify it directly
                    }
                }
            } catch {
                print("Error deleting meal: \(error.localizedDescription)")
            }
        }
    }
}

struct DailySummary: Identifiable {
    var id = UUID()
    var date: Date
    var totalCalories: Double
    var mealsByType: [MealPeriod: SimpleMeal]
    
    var mealCount: Int {
        return mealsByType.count
    }
}

struct NutritionSummary {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}

// Helper method to get meals filtered by period and date
// private func filteredMealsFor(period: ViewPeriod, date: Date, mealPeriod: MealPeriod) -> [SimpleMeal] {
//     ... removed ...
// } 
