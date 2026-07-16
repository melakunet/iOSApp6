// ContentView.swift
// CoinWatch — landing screen and main content entry point

import SwiftUI

// Root view: shows the landing screen, then switches to main content on tap
struct ContentView: View {
    // Controls whether the main content is visible
    @State private var showMain = false

    var body: some View {
        if showMain {
            // Markets screen showing live coin prices
            CoinListView()
        } else {
            // Pass a closure so LandingView can trigger the transition
            LandingView {
                withAnimation(.easeInOut) {
                    showMain = true
                }
            }
        }
    }
}

// Animated landing screen shown when the app first opens
struct LandingView: View {
    // Called when the user taps Get Started
    var onStart: () -> Void

    // Rotation angle for the initial coin spin
    @State private var spinAngle: Double = 0
    // Vertical offset for the continuous float after the spin
    @State private var floatOffset: CGFloat = 0
    // Shadow radius for the pulsing yellow glow on the coin
    @State private var glowRadius: CGFloat = 20
    // Scale factor for the button pulse animation
    @State private var buttonScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dark gradient background from black to indigo
            LinearGradient(
                colors: [.black, Color.indigo],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Bitcoin icon: spins once on appear, then floats and glows forever
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 110))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: glowRadius, x: 0, y: 0)
                    .rotationEffect(.degrees(spinAngle))
                    .offset(y: floatOffset)
                    .onAppear {
                        // Spin once on appear (flat 2D rotation so coin stays fully visible)
                        withAnimation(.linear(duration: 1.5)) {
                            spinAngle = 360
                        }
                        // After the spin, start a gentle float and glow pulse forever
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                                floatOffset = -12
                                glowRadius = 36
                            }
                        }
                    }

                // App name — always visible, slides up from a slight offset on appear
                Text("CoinWatch")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                // Subtitle — always visible below the title
                Text("Live crypto prices")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                // Get Started button — always visible, pulses to invite a tap
                Button(action: onStart) {
                    Text("Get Started")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.yellow))
                }
                .scaleEffect(buttonScale)
                .onAppear {
                    // Start a gentle scale pulse so the button draws attention
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        buttonScale = 1.06
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
