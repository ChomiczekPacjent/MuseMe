//
//  Session.swift
//  MuseMe
//
//  Created by Błażej Faber on 02/06/2025.
//

import Foundation

struct Session: Identifiable, Codable {
    var id = UUID()
    var startTime: Date
    var endTime: Date
}
