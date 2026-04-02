import SwiftUI

struct HealMeView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @ObservedObject private var session = ActiveSessionManager.shared
    @ObservedObject private var auth = SpotifyAuthManager.shared

    @State private var showConnectView = false
    @State private var now = Date()
    @State private var displayTimer: Timer?

    var isSpotifyConnected: Bool { auth.accessToken != nil }

    var elapsed: TimeInterval {
        guard session.isSessionActive,
              session.currentMode == .heal,
              let start = session.sessionStartTime
        else { return 0 }
        return now.timeIntervalSince(start)
    }

    var timerString: String {
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        let s = Int(elapsed) % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("finallogo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(session.isSessionActive && session.currentMode == .heal ? 1.0 : 0.3)
                .animation(.easeInOut(duration: 0.4), value: session.isSessionActive)

            Text(session.isSessionActive && session.currentMode == .heal ? timerString : "00:00")
                .font(.system(size: 48, weight: .thin, design: .monospaced))
                .foregroundColor(session.isSessionActive && session.currentMode == .heal ? .white : Color.gray.opacity(0.4))
                .padding(.top, 28)
                .animation(.easeInOut(duration: 0.3), value: session.isSessionActive)

            Spacer()

            if !isSpotifyConnected {
                spotifyPrompt
            } else {
                sessionButton(mode: .heal)
            }

            Spacer().frame(height: 40)
        }
        .background(Color.black.ignoresSafeArea())
        .tint(.white)
        .sheet(isPresented: $showConnectView) { ConnectView() }
        .onAppear {
            startDisplayTimerIfNeeded()
        }
        .onChange(of: session.isSessionActive) {
            startDisplayTimerIfNeeded()
        }
        .onDisappear {
            displayTimer?.invalidate()
            displayTimer = nil
        }
    }

    private func startDisplayTimerIfNeeded() {
        displayTimer?.invalidate()
        displayTimer = nil

        now = Date()

        guard session.isSessionActive else { return }

        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            now = Date()
        }
    }

    private var spotifyPrompt: some View {
        VStack(spacing: 12) {
            Image("finallogo")
                .resizable()
                .scaledToFit()
                .frame(height: 60)
            Text("Connect Spotify to get started")
                .foregroundColor(.gray)
                .font(.subheadline)
            Button("Connect") { showConnectView = true }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }

    private func sessionButton(mode: SessionMode) -> some View {
        let isActive = session.isSessionActive && session.currentMode == mode
        return Button(action: {
            isActive
                ? session.stopSession(sessionStore: sessionStore)
                : session.startSession(mode: mode, sessionStore: sessionStore)
        }) {
            Text(isActive ? "Stop" : "Start")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isActive ? Color.red : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}
