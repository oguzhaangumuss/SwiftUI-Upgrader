import SwiftUI

struct AppTheme {
    // Main colors
    static let primaryColor = Color(red: 0.18, green: 0.65, blue: 0.60) // Teal/Green
    static let secondaryColor = Color(red: 0.94, green: 0.33, blue: 0.31) // Red
    static let accentColor = Color(red: 0.98, green: 0.80, blue: 0.18) // Yellow
    
    // Navigation colors
    static let navigationBarColor = Color.black
    static let navigationBarTextColor = Color.white
    
    // Neutral colors
    static let backgroundColor = Color(UIColor.systemBackground)
    static let cardBackgroundColor = Color(UIColor.secondarySystemBackground)
    static let dividerColor = Color(UIColor.separator)
    
    // Text colors
    static let primaryTextColor = Color(UIColor.label)
    static let secondaryTextColor = Color(UIColor.secondaryLabel)
    static let tertiaryTextColor = Color(UIColor.tertiaryLabel)
    static let textColor = Color(UIColor.label) // Alias for primaryTextColor for backward compatibility
    
    // Category colors
    static let workoutColor = Color(red: 0.2, green: 0.6, blue: 0.86)
    static let foodColor = Color(red: 0.33, green: 0.69, blue: 0.31)
    static let calorieColor = Color(red: 0.9, green: 0.4, blue: 0.32)
    static let proteinColor = Color(red: 0.36, green: 0.56, blue: 0.7)
    static let carbsColor = Color(red: 0.65, green: 0.47, blue: 0.73)
    static let fatColor = Color(red: 0.93, green: 0.69, blue: 0.13)
    
    // Button styles
    static var primaryButtonStyle: some PrimitiveButtonStyle {
        return .automatic
    }
    
    // Configure the global app appearance
    static func configureAppTheme() {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = UIColor(navigationBarColor)
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor(navigationBarTextColor)]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(navigationBarTextColor)]
        
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = UIColor(navigationBarTextColor)
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(primaryColor)
    }
}

// Custom Modifiers
struct CustomTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .foregroundColor(AppTheme.primaryTextColor)
            .fontWeight(.bold)
    }
}

struct CustomSubtitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(AppTheme.secondaryTextColor)
    }
}

struct CustomBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(AppTheme.primaryTextColor)
    }
}

struct CustomCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Extension to apply text styles easily
extension View {
    func titleStyle() -> some View {
        self.modifier(CustomTitleStyle())
    }
    
    func subtitleStyle() -> some View {
        self.modifier(CustomSubtitleStyle())
    }
    
    func bodyStyle() -> some View {
        self.modifier(CustomBodyStyle())
    }
    
    func cardStyle() -> some View {
        self.modifier(CustomCardStyle())
    }
} 
