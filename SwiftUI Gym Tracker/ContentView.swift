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
            
            // Only show AI button if user is logged in
            if firebaseManager.currentUser != nil {
                FloatingAIButton(showingAIAssistant: $showingAIAssistant)
                    .zIndex(1) // Make sure button is above other UI elements
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIAssistantView()
        }
    }
}

#Preview {
    ContentView()
    
//    WelcomeView()
//    SignInView()
//    MainTabView()
//    
    
}
