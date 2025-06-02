import SwiftUI
import FirebaseFirestore

struct AddMealView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MealsViewModel
    @State private var selectedFood: Food?
    @State private var quantity = ""
    @State private var note = ""
    @State private var errorMessage = ""
    @State private var showingFoodPicker = false
    @State private var isLoading = false
    
    // Parameters passed from parent view
    var selectedDate: Date
    @State private var mealDate: Date
    @State private var selectedMealType: MealType
    @Binding var showSheet: Bool
    
    // Initialize with default parameters
    init(selectedDate: Date = Date(), selectedMealType: MealType = .breakfast) {
        self.selectedDate = selectedDate
        self._mealDate = State(initialValue: selectedDate)
        self._selectedMealType = State(initialValue: selectedMealType)
        self._showSheet = .constant(true) // Default binding that can be overridden
    }
    
    // Initialize with showSheet binding
    init(showSheet: Binding<Bool>, selectedDate: Binding<Date>) {
        self.selectedDate = selectedDate.wrappedValue
        self._mealDate = State(initialValue: selectedDate.wrappedValue)
        self._selectedMealType = State(initialValue: .breakfast)
        self._showSheet = showSheet
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tarih ve Öğün")) {
                    DatePicker("Tarih", selection: $mealDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    Picker("Öğün", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Yemek Seçimi")) {
                    Button(action: {
                        showingFoodPicker = true
                    }) {
                        HStack {
                            Text(selectedFood?.name ?? "Yemek Seçin")
                                .foregroundColor(selectedFood == nil ? .secondary : .primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let food = selectedFood {
                        HStack {
                            Text("Kalori:")
                            Spacer()
                            Text("\(Int(food.calories)) kcal / 100g")
                        }
                        
                        HStack {
                            Text("Protein:")
                            Spacer()
                            Text("\(String(format: "%.1f", food.protein))g / 100g")
                        }
                        
                        HStack {
                            Text("Karbonhidrat:")
                            Spacer()
                            Text("\(String(format: "%.1f", food.carbs))g / 100g")
                        }
                        
                        HStack {
                            Text("Yağ:")
                            Spacer()
                            Text("\(String(format: "%.1f", food.fat))g / 100g")
                        }
                    }
                }
                
                Section(header: Text("Miktar ve Detaylar")) {
                    TextField("Miktar (gram)", text: $quantity)
                        .keyboardType(.decimalPad)
                    
                    TextField("Not (isteğe bağlı)", text: $note)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: addMeal) {
                        Text("Öğüne Ekle")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .background(selectedFood == nil ? Color.gray : AppTheme.primaryColor)
                            .cornerRadius(8)
                    }
                    .disabled(selectedFood == nil || isLoading)
                }
            }
            .navigationTitle("Öğün Ekle")
            .navigationBarItems(trailing: Button("İptal") {
                dismiss()
                showSheet = false
            })
            .sheet(isPresented: $showingFoodPicker) {
                FoodsPickerView(selectedFood: $selectedFood)
            }
        }
    }
    
    private func addMeal() {
        guard let food = selectedFood else {
            errorMessage = "Lütfen bir yemek seçin"
            return
        }
        
        guard let quantityDouble = Double(quantity), quantityDouble > 0 else {
            errorMessage = "Lütfen geçerli bir miktar girin"
            return
        }
        
        guard let userId = FirebaseManager.shared.auth.currentUser?.uid else {
            errorMessage = "Kullanıcı oturumu bulunamadı"
            return
        }
        
        isLoading = true
        
        let mealData: [String: Any] = [
            "userId": userId,
            "mealType": selectedMealType.rawValue,
            "date": Timestamp(date: mealDate),
            "foods": [[
                "foodId": food.id!,
                "portion": quantityDouble
            ]],
            "createdAt": Timestamp(date: Date())
        ]
        
        Task {
            do {
                try await FirebaseManager.shared.firestore
                    .collection("userMeals")
                    .document()
                    .setData(mealData)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    showSheet = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Öğün eklenirken hata oluştu: \(error.localizedDescription)"
                }
            }
        }
    }
}

// A simple picker view to select foods
struct FoodsPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FoodsViewModel.shared
    @State private var searchText = ""
    @Binding var selectedFood: Food?
    
    var filteredFoods: [Food] {
        if searchText.isEmpty {
            return viewModel.foods
        } else {
            return viewModel.foods.filter { food in
                food.name.localizedCaseInsensitiveContains(searchText) ||
                food.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredFoods) { food in
                    Button(action: {
                        selectedFood = food
                        dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.headline)
                            
                            if !food.brand.isEmpty {
                                Text(food.brand)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("\(Int(food.calories)) kcal")
                                Text("•")
                                Text("P: \(Int(food.protein))g")
                                Text("•")
                                Text("K: \(Int(food.carbs))g")
                                Text("•")
                                Text("Y: \(Int(food.fat))g")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Yemek Seç")
            .navigationBarItems(trailing: Button("İptal") {
                dismiss()
            })
            .searchable(text: $searchText, prompt: "Yemek ara")
        }
    }
} 