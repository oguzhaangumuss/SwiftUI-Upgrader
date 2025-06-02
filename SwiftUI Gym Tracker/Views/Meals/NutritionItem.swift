import SwiftUI

struct NutritionItem: View {
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Rectangle()
                .frame(height: 4)
                .foregroundColor(color)
        }
    }
}

struct NutritionItem_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            NutritionItem(title: "Calories", value: "2000 kcal", color: .red)
            NutritionItem(title: "Protein", value: "150g", color: .blue)
            NutritionItem(title: "Carbs", value: "250g", color: .green)
            NutritionItem(title: "Fat", value: "80g", color: .yellow)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
