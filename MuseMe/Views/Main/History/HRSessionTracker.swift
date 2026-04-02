//
//  HRSessionTracker.swift
//  MuseMe
//
//  Created by Błażej Faber on 10/12/2025.
//

import Foundation

class HRSessionTracker: ObservableObject {
    static let shared = HRSessionTracker()
    
    @Published var values: [Int] = []
    @Published var timestamps: [Date] = []   

    func reset() {
        values.removeAll()
        timestamps.removeAll()
    }
    
    func add(_ bpm: Int) {
        values.append(bpm)
        timestamps.append(Date())
    }
    
    var avg: Int? {
        guard !values.isEmpty else { return nil }
        return Int(values.reduce(0, +) / values.count)
    }
    
    var min: Int? {
        values.min()
    }
    
    var max: Int? {
        values.max()
    }
}
