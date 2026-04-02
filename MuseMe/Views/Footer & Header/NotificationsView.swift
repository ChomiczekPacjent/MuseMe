//
//  NotificationsView.swift
//  MuseMe
//
//  Created by Błażej Faber on 15/04/2025.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var viewModel: NotificationsViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if viewModel.notifications.isEmpty {
                Image(systemName: "bell.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundColor(.gray)

                Text("No notifications yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("You're all caught up")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                List(viewModel.notifications, id: \.id) { notification in
                    VStack(alignment: .leading) {
                        Text(notification.title)
                            .font(.headline)
                        Text(notification.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .listStyle(PlainListStyle())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
