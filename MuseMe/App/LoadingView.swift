//
//  SDWebImage.swift
//  MuseMe
//
//  Created by Błażej Faber on 02/04/2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                AnimatedImage(name: "museme_pulse_motion.gif")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Text("Ładowanie...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}

#Preview {
    LoadingView()
}

