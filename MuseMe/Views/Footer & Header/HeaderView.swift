//
//  HeaderView\.swift
//  MuseMe
//
//  Created by Błażej Faber on 22/02/2025.
//

import SwiftUI

struct HeaderView: View {
    @Binding var selectedTab: FooterTab
    @EnvironmentObject var viewModel: AuthViewModel

    @ObservedObject private var hrBLE = HeartRateBLE.shared

    var body: some View {
        HStack {
            Button(action: { selectedTab = .profile }) {
                if let user = viewModel.currentUser {
                    Text(user.initials)
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.gray)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable().frame(width: 32, height: 32)
                        .foregroundColor(.white)
                }
            }

            Spacer()

            if hrBLE.heartRateBLE > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.purple)
                    Text("\(Int(hrBLE.heartRateBLE)) bpm")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .onTapGesture {
                    HeartRateBLE.shared.stop()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        HeartRateBLE.shared.start()
                    }
                }
                .accessibilityLabel("Heart rate \(Int(hrBLE.heartRateBLE)) beats per minute")
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "heart.slash")
                        .foregroundColor(.gray)
                    Text("— bpm")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .onTapGesture { HeartRateBLE.shared.start() }
                .accessibilityLabel("Heart rate unavailable. Tap to connect.")
            }

            Spacer()

            Button(action: { selectedTab = .notifications }) {
                Image(systemName: "bell")
                    .resizable().frame(width: 20, height: 20)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(Color.spotifyBackground)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            HeartRateBLE.shared.start()
        }
    }
}
