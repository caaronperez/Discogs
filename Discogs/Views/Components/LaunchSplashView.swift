//
//  LaunchSplashView.swift
//  Discogs
//
//  Created by Cristian Perez on 2/28/26.
//

import SwiftUI

struct LaunchSplashView: View {
    let onFinished: () -> Void

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            ZStack {
                Image("VinylLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(rotationAngle(at: context.date)))
                    .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            .appThemeBackground()
        }
        .task {
            startDate = Date()
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            onFinished()
        }
    }

    private func rotationAngle(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(startDate)
        let stillDuration = 0.35
        let accelerationDuration = 1.1
        let maxAngularSpeed = 900.0

        guard elapsed > stillDuration else { return 0 }

        let acceleratedTime = elapsed - stillDuration
        if acceleratedTime < accelerationDuration {
            let angularAcceleration = maxAngularSpeed / accelerationDuration
            return 0.5 * angularAcceleration * acceleratedTime * acceleratedTime
        }

        let angleDuringAcceleration = 0.5 * maxAngularSpeed * accelerationDuration
        let angleAfterAcceleration = maxAngularSpeed * (acceleratedTime - accelerationDuration)
        return angleDuringAcceleration + angleAfterAcceleration
    }
}

#Preview {
    LaunchSplashView(onFinished: {})
}
