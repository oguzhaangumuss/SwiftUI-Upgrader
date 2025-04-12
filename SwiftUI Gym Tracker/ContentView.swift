//
//  ContentView.swift
//  SwiftUI Gym Tracker
//
//  Created by oguzhangumus on 3.12.2024.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingSignIn = false
    @State private var previousUserId: String? = nil
    @State private var showingAIAssistant = false
    @State private var showAIButton = true
    
    var body: some View {
        ZStack {
            Group {
                if firebaseManager.currentUser != nil {
                    if firebaseManager.currentUser?.isAdmin == true {
                        AdminTabView()
                    } else {
                        MainTabView()
                    }
                } else {
                    WelcomeView()
                }
            }
            .onAppear {
                if Auth.auth().currentUser == nil {
                    showingSignIn = true
                }
                
                // AI asistanı görünürlüğü için UserDefaults kontrolü
                checkAIAssistantVisibility()
                
                // Log user status on appear instead of inside the View body
                if let user = firebaseManager.currentUser {
                    if user.isAdmin {
                        print("👑 ContentView: Admin kullanıcı tespit edildi - \(user.email)")
                    } else {
                        print("👤 ContentView: Normal kullanıcı tespit edildi - \(user.email), admin: \(user.isAdmin)")
                    }
                    previousUserId = user.id
                }
            }
            .onChange(of: firebaseManager.currentUser?.id) { newUserId in
                // Only log when the user ID has changed
                if newUserId != previousUserId, let user = firebaseManager.currentUser {
                    if user.isAdmin {
                        print("👑 ContentView: Admin kullanıcı tespit edildi - \(user.email)")
                    } else {
                        print("👤 ContentView: Normal kullanıcı tespit edildi - \(user.email), admin: \(user.isAdmin)")
                    }
                    previousUserId = newUserId
                }
            }
            
            // Only show AI button if user is logged in and button is not hidden
            if firebaseManager.currentUser != nil && showAIButton {
                FloatingAIButton(showingAIAssistant: $showingAIAssistant)
                    .zIndex(1) // Make sure button is above other UI elements
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIAssistantView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AIAssistantVisibilityChanged"))) { _ in
            checkAIAssistantVisibility()
        }
    }
    
    private func checkAIAssistantVisibility() {
        // Eğer UserDefaults'ta değer yoksa varsayılan olarak true kullan
        showAIButton = UserDefaults.standard.object(forKey: "showAIAssistant") as? Bool ?? true
    }
}

#Preview {
    ContentView()
    
//    WelcomeView()
//    SignInView()
//    MainTabView()
//    
    
}
