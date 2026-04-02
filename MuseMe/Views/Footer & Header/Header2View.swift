//
//  Header2View.swift
//  MuseMe
//
//  Created by Błażej Faber on 16/04/2025.
//

import SwiftUI
import SDWebImageSwiftUI

struct Header2View: View {
    @ObservedObject var healthView: HealthView
    @Binding var selectedTab: FooterTab
    @EnvironmentObject var viewModel: AuthViewModel

    var body: some View {
        HStack {
            Button(action: {
                selectedTab = .home
            }) {
                if let user = viewModel.currentUser {
                    Text(user.initials)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.gray)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .padding(.top, 2)
                }
            }

            Spacer()

            if let hr = healthView.heartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.purple)
                    Text("\(hr)")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
            } else {
                Image(systemName: "heart.slash")
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: {
                selectedTab = .notifications
            }) {
                Image(systemName: "bell")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44, alignment: .top) 
        .frame(maxWidth: .infinity)
        .background(Color.spotifyBackground)
        .ignoresSafeArea(edges: .top)
    }
}
