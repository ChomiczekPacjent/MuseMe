//
//  ConnectedHealthSection.swift
//  MuseMe
//
//  Created by Błażej Faber on 01/05/2025.
//

import SwiftUI

struct ConnectedHealthSection: View {
    @ObservedObject var healthStore: HealthStore

    var body: some View {
        VStack(spacing: 12) {
            Text("Apple Health Connected")
                .foregroundColor(.gray)
                .font(.subheadline)

            VitalsTile(title: "Heart Rate", value: String(format: "%.0f bpm", healthStore.heartRate), icon: "heart.fill")
            VitalsTile(title: "Steps Today", value: String(format: "%.0f", healthStore.steps), icon: "figure.walk")
            VitalsTile(title: "Calories", value: String(format: "%.0f kcal", healthStore.calories), icon: "flame.fill")
        }
        .padding(.horizontal)
    }
}
