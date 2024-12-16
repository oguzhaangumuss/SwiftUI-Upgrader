//import SwiftUI
//import FirebaseCore
//
//classp AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication,
//                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//        return true
//    }
//}
//
//@main
//struct SwiftUIGymTrackerApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject private var firebaseManager = FirebaseManager.shared
//    
//    init() {
//        AppTheme.configureAppTheme()
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .preferredColorScheme(.dark)
//        }
//    }
//} 
