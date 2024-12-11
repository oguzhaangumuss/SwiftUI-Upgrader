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
    
    
    var body: some View {
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
