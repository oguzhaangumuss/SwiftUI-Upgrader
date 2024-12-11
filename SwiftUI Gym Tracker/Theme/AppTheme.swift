import SwiftUI

enum AppTheme {
    static let backgroundColor = Color.black
    static let surfaceColor = Color(.systemGray6)
    static let primaryColor = Color.blue
    static let textColor = Color.white
    static let secondaryTextColor = Color.gray
    static let accentColor = Color.blue
    
    static func configureAppTheme() {
        // UINavigationBar ayarları
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // TabBar ayarları
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .black
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // List ayarları
        UITableView.appearance().backgroundColor = .black
    }
} 