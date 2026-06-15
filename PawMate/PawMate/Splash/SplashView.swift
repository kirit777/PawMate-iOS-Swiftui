//
//  SplashView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.65
    @State private var logoOpacity: Double = 0
    @State private var pawRotation: Double = -12
    @State private var textOffset: CGFloat = 22
    @State private var textOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            animatedBackground

            VStack(spacing: 22) {
                logoView

                VStack(spacing: 8) {
                    Text(AppConstants.appName)
                        .font(.system(size: dynamicTitleSize, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(AppConstants.appTagline)
                        .font(.system(size: dynamicSubtitleSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                }
                .offset(y: textOffset)
                .opacity(textOpacity)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startAnimation()
        }
    }

    private var logoView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primary.opacity(0.35),
                            AppColors.secondary.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: logoSize * 1.8, height: logoSize * 1.8)
                .scaleEffect(glowScale)
                .blur(radius: 10)

            Image("iconApp")
                .resizable()
                .scaledToFill()
                .frame(width: logoSize, height: logoSize)
                .clipShape(Circle())
                .shadow(color: AppColors.primary.opacity(0.22), radius: 28, x: 0, y: 18)
        }
        .rotationEffect(.degrees(pawRotation))
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }

    private var animatedBackground: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.13))
                    .frame(width: geo.size.width * 0.62)
                    .blur(radius: 30)
                    .offset(x: -geo.size.width * 0.36, y: -geo.size.height * 0.32)

                Circle()
                    .fill(AppColors.secondary.opacity(0.14))
                    .frame(width: geo.size.width * 0.72)
                    .blur(radius: 36)
                    .offset(x: geo.size.width * 0.38, y: geo.size.height * 0.32)

                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: CGFloat(18 + index * 3), weight: .bold))
                        .foregroundColor(index.isMultiple(of: 2) ? AppColors.primary.opacity(0.12) : AppColors.secondary.opacity(0.12))
                        .offset(
                            x: pawX(index, geo.size.width),
                            y: pawY(index, geo.size.height)
                        )
                }
            }
        }
        .ignoresSafeArea()
    }

    private var logoSize: CGFloat {
        let width = UIScreen.main.bounds.width
        if width <= 350 { return 118 }
        if width <= 390 { return 138 }
        return 154
    }

    private var dynamicTitleSize: CGFloat {
        let width = UIScreen.main.bounds.width
        if width <= 350 { return 42 }
        if width <= 390 { return 48 }
        return 54
    }

    private var dynamicSubtitleSize: CGFloat {
        UIScreen.main.bounds.width <= 350 ? 15 : 17
    }

    private func pawX(_ index: Int, _ width: CGFloat) -> CGFloat {
        let values: [CGFloat] = [-0.34, 0.32, -0.18, 0.22, -0.38, 0.38]
        return width * values[index]
    }

    private func pawY(_ index: Int, _ height: CGFloat) -> CGFloat {
        let values: [CGFloat] = [-0.36, -0.24, 0.05, 0.18, 0.34, 0.39]
        return height * values[index]
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.62)) {
            logoScale = 1
            logoOpacity = 1
            pawRotation = 0
        }

        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            glowScale = 1.08
        }

        withAnimation(.easeOut(duration: 0.7).delay(0.35)) {
            textOffset = 0
            textOpacity = 1
        }
    }
}

#Preview {
    SplashView()
}
