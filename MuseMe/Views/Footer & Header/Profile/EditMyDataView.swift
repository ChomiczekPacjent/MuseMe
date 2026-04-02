//
//  EditMyDataView.swift
//  MuseMe
//
//  Created by Błażej Faber on 11/12/2025.
//

import SwiftUI

struct EditMyDataView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State var profile: ProfileData
    @State private var isSaving = false

    var body: some View {
        Form {
            Section(header: Text("Personal")) {
                TextField("Gender", text: $profile.gender)
                DatePicker("Birth Date", selection: $profile.birthDate, displayedComponents: .date)
                TextField("Height", value: $profile.height, formatter: NumberFormatter())
                TextField("Weight", value: $profile.weight, formatter: NumberFormatter())
            }

            Section(header: Text("Health")) {
                TextField("Disease", text: $profile.disease)
            }

            Section(header: Text("Music Preferences")) {
                TextField("Favorite Genre", text: $profile.genre)
            }

            Button("Save") {
                Task {
                    isSaving = true
                    try? await authViewModel.saveProfileData(profile)
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit My Data")
    }
}

