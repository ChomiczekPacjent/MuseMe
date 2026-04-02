//
//  MuseMeApp.swift
//  MuseMe
//
//  Created by Błażej Faber on 13/02/2025.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct MuseMeApp: App {
    @StateObject var sessionManager = SessionManager.shared
    @StateObject var viewModel = AuthViewModel()
    @StateObject var sessionStore = SessionStore()
    @StateObject var notificationsViewModel = NotificationsViewModel.shared

    init(){
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .environmentObject(viewModel)
                .environmentObject(sessionStore)
                .environmentObject(notificationsViewModel)
        }
    }
}
