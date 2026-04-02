//
//  NotificationViewModel.swift
//  MuseMe
//
//  Created by Błażej Faber on 02/06/2025.
//

class NotificationsViewModel: ObservableObject {
    static let shared = NotificationsViewModel()
    
    @Published var notifications: [NotificationItem] = []
    
    func addNotification(title: String, body: String) {
        let newNotification = NotificationItem(title: title, date: Date())
        notifications.insert(newNotification, at: 0) 
    }
}
