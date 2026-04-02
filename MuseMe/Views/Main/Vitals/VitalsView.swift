//
//  VitalsView.swift
//  MuseMe
//

import SwiftUI

struct VitalsView: View {
    @ObservedObject var healthStore: HealthStore
    
    @ObservedObject private var ble = HeartRateBLE.shared

    @State private var isHealthAuthorized = false
    @State private var showConnectSheet = false

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private var heartRateText: String {
        let bleHR = Int(ble.heartRateBLE)
        if bleHR > 0 {
            return "\(bleHR) bpm"
        } else if healthStore.heartRate > 0 {
            return String(format: "%.0f bpm", healthStore.heartRate)
        } else {
            return "-- bpm"
        }
    }

    private var heartRateSourceLabel: String {
        ble.heartRateBLE > 0 ? "Source: Garmin (BLE, live)" : "Source: HealthKit"
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isHealthAuthorized {
                Text("Please connect with Health to view your data.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button("Connect with Health") {
                    healthStore.requestAuthorization { success in
                        isHealthAuthorized = success
                        if success {
                            healthStore.fetchAllData()
                            healthStore.startHeartRateUpdates()
                        }
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.bottom, 32)
            } else {
                ScrollView {
                    VitalsTile(
                        title: "Heart Rate",
                        value: heartRateText,
                        icon: "waveform.path.ecg"
                    )

                    Text(heartRateSourceLabel)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)

                    if let date = healthStore.lastHeartRateDate {
                        Text("Last HK update: \(date, formatter: timeFormatter)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.bottom, 12)
                    }

                    VitalsTile(
                        title: "Steps Today",
                        value: String(format: "%.0f", healthStore.steps),
                        icon: "figure.walk"
                    )

                    VitalsTile(
                        title: "Calories",
                        value: String(format: "%.0f kcal", healthStore.calories),
                        icon: "flame.fill"
                    )

                   
                }
                .padding()
            }
        }
        .onAppear {
            healthStore.checkIfAuthorized { isAuth in
                isHealthAuthorized = isAuth
                if isAuth {
                    healthStore.fetchAllData()
                    healthStore.startHeartRateUpdates()
                }
            }
            HeartRateBLE.shared.start()
        }
        .onDisappear {
            healthStore.stopHeartRateUpdates()
            HeartRateBLE.shared.stop()
        }
        .background(Color.black.ignoresSafeArea())
    }
}
