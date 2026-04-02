//
//  Vitals.swift
//  MuseMe
//
//  Created by Błażej Faber on 01/05/2025.
//

import SwiftUI

struct VitalsTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 32)
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text(value)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}
