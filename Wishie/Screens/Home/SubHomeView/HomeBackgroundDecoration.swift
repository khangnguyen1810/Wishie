//
//  HomeBackgroundDecoration.swift
//  Wishie
//

import SwiftUI

struct HomeBackgroundDecoration: View {
    var celebrationFloat: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF8E8"), Color(hex: "#FBEACB")],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#D4AF6A").opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 85
                    )
                )
                .frame(width: 170, height: 170)
                .offset(x: 100, y: -340)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#6FE3D0").opacity(0.8))
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(20))
                .offset(x: -140, y: -300)
            Circle()
                .fill(Color(hex: "#F4667A").opacity(0.7))
                .frame(width: 8, height: 8)
                .offset(x: 140, y: -270)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#B79CF2").opacity(0.75))
                .frame(width: 9, height: 9)
                .rotationEffect(.degrees(-15))
                .offset(x: 95, y: -330)
            Circle()
                .fill(Color(hex: "#E7B65A").opacity(0.7))
                .frame(width: 7, height: 7)
                .offset(x: -120, y: -200)
                .offset(y: celebrationFloat ? -6 : 0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: celebrationFloat)
        }
        .allowsHitTesting(false)
    }
}
