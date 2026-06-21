//
//  ZTixSplash.swift
//  Z-Tix
//
//  Created by Harnish Patel on 25/9/2025.
//

import SwiftUI

// MARK: - Splash Screen View

/// First-time user onboarding splash screen
/// Displays app branding and provides entry point to authentication flow
/// Only shown once per installation, tracked by SplashManager
struct ZTixSplash: View {

    // MARK: - Properties

    /// Authentication view model for potential automatic navigation
    /// Currently not used for direct navigation but available for future enhancements
    @EnvironmentObject var authViewModel: AuthViewModel

    // MARK: - Body

    var body: some View {
        ZStack {

            // MARK: Background Gradient
            /// Creates branded gradient background from cyan to white
            LinearGradient(
                gradient: Gradient(colors: [.cyan, .white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MARK: Content Stack
            VStack {

                Spacer()

                // MARK: Welcome Text
                Text("Welcome to")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 5)

                // MARK: App Logo
                /// Main Z-Tix branding logo
                Image("Z-Tix_Text_Logo")
                    .resizable()
                    .frame(width: 300, height: 150)
                    .aspectRatio(contentMode: .fit)

                // MARK: Slogan
                Text("Tickets at Z-speed.")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // MARK: Get Started Button
                /// Navigation link to login screen with splash tracking
                /// simultaneousGesture ensures splash is marked as seen even if navigation fails
                NavigationLink(destination: LoginView()) {
                    ZTixButton(
                        title: "Get Started",
                        foregroundColour: .white,
                        backgroundColour: .cyan,
                        opacity: 1
                    )
                }
                .simultaneousGesture(
                    // Mark splash as seen immediately on tap
                    // This prevents showing splash again if user navigates back
                    TapGesture().onEnded {
                        SplashManager.markSplashAsSeen()
                    }
                )
                .padding(10)
            }
            // Prevent back navigation to maintain one-time splash behavior
            .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ZTixSplash()
    }

}
