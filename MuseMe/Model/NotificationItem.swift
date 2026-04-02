//
//  NotificationItem.swift
//  MuseMe
//
//  Created by Błażej Faber on 02/06/2025.
//

import Foundation

struct NotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
}
