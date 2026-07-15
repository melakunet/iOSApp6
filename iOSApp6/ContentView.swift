// ContentView.swift
// CoinWatch — landing screen and main content entry point

import SwiftUI

// Root view: shows the landing screen, then switches to main content
struct ContentView: View {
    // Controls whether the main content is visible
    @State private var showMain = false

    var body: some View {
        if showMain {
            // Placeholder until the real Markets screen is built
            Text("Markets coming soon")
                .font(.title2)
                .foregroundStyle(.secondary)
        } else {
            LandingView()
                .onAppear {
                    // Switch to main content after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showMain = true
                        }
                    }
                }
        }
    }
}

// Animated launch screen shown when the app first opens
struct LandingView: View {
    // Rotation angle for the coin spin animation
    @State private var spinAngle: Double = 0
    // Opacity for the title and subtitle fade-in
    @State private var titleOpacity: Double = 0
    // Vertical offset for the title slide-up animation
    @State private var titleOffset: CGFloat = 30

    var body: some View {
        ZStack {
            // Dark gradient background from black to indigo
            LinearGradient(
                colors: [.black, Color.indigo],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Bitcoin icon with yellow glow, spins on appear
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 110))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 20, x: 0, y: 0)
                    .rotation3DEffect(.degrees(spinAngle), axis: (x: 0, y: 1, z: 0))
                    .onAppear {
                        // Spin two full rotations over 2 seconds
                        withAnimation(.linear(duration: 2)) {
                            spinAngle = 720
                        }
                    }

                // App name fades in and slides up after a short delay
                Text("CoinWatch")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1).delay(0.6)) {
                            titleOpacity = 1
                            titleOffset = 0
                        }
                    }

                // Subtitle shares the same opacity so it fades in with the title
                Text("Live crypto prices")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .opacity(titleOpacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
