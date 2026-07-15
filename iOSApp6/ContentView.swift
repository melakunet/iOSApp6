// ContentView.swift
// CoinWatch — landing screen and main content entry point

import SwiftUI

// Root view: shows the landing screen, then switches to main content on tap
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
    // Opacity for the title and subtitle fade-in
    @State private var titleOpacity: Double = 0
    // Vertical offset for the title slide-up animation
    @State private var titleOffset: CGFloat = 30
    // Opacity for the Get Started button fade-in
    @State private var buttonOpacity: Double = 0
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
                    .rotation3DEffect(.degrees(spinAngle), axis: (x: 0, y: 1, z: 0))
                    .offset(y: floatOffset)
                    .onAppear {
                        // Spin two full rotations over 2 seconds
                        withAnimation(.linear(duration: 2)) {
                            spinAngle = 720
                        }
                        // After the spin finishes, start a gentle float and glow pulse
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                                floatOffset = -12
                                glowRadius = 36
                            }
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

                // Subtitle shares opacity so it fades in with the title
                Text("Live crypto prices")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .opacity(titleOpacity)

                // Get Started button fades in after the title and pulses to invite a tap
                Button(action: onStart) {
                    Text("Get Started")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.yellow))
                }
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .onAppear {
                    // Fade the button in slightly after the title finishes
                    withAnimation(.easeOut(duration: 0.8).delay(1.8)) {
                        buttonOpacity = 1
                    }
                    // Start the scale pulse once the button is fully visible
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            buttonScale = 1.06
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
