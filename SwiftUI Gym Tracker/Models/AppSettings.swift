import SwiftUI

class AppSettings: ObservableObject {
    // Theme settings
    @Published var isDarkMode: Bool = true
    
    // User preferences
    @Published var showCaloriesInSummary: Bool = true
    @Published var showAIAssistant: Bool = true
    
    // Notification settings
    @Published var reminderNotificationsEnabled: Bool = true
    @Published var workoutReminderTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Unit preferences
    @Published var useMetricSystem: Bool = true
    
    init() {
        // Load saved preferences from UserDefaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.showCaloriesInSummary = UserDefaults.standard.bool(forKey: "showCaloriesInSummary")
        self.showAIAssistant = UserDefaults.standard.bool(forKey: "showAIAssistant")
        self.reminderNotificationsEnabled = UserDefaults.standard.bool(forKey: "reminderNotificationsEnabled")
        self.useMetricSystem = UserDefaults.standard.bool(forKey: "useMetricSystem")
        
        if let savedTime = UserDefaults.standard.object(forKey: "workoutReminderTime") as? Date {
            self.workoutReminderTime = savedTime
        }
    }
    
    // Save settings to UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(showCaloriesInSummary, forKey: "showCaloriesInSummary")
        UserDefaults.standard.set(showAIAssistant, forKey: "showAIAssistant")
        UserDefaults.standard.set(reminderNotificationsEnabled, forKey: "reminderNotificationsEnabled")
        UserDefaults.standard.set(workoutReminderTime, forKey: "workoutReminderTime")
        UserDefaults.standard.set(useMetricSystem, forKey: "useMetricSystem")
    }
    
    // Theme toggling
    func toggleDarkMode() {
        isDarkMode.toggle()
        saveSettings()
    }
    
    // AI Assistant visibility
    func toggleAIAssistant() {
        showAIAssistant.toggle()
        saveSettings()
        NotificationCenter.default.post(name: NSNotification.Name("AIAssistantVisibilityChanged"), object: nil)
    }
    
    // Update notification settings
    func updateNotificationSettings(enabled: Bool) {
        reminderNotificationsEnabled = enabled
        saveSettings()
    }
    
    // Update reminder time
    func updateReminderTime(_ time: Date) {
        workoutReminderTime = time
        saveSettings()
    }
    
    // Toggle metric system
    func toggleMetricSystem() {
        useMetricSystem.toggle()
        saveSettings()
    }
} 