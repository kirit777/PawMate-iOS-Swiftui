//
//  OnboardingView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    var onComplete: (() -> Void)? = nil

    @State private var selectedIndex = 0
    @State private var animateContent = false

    private let pages: [OnboardingPage] = [
        .init(
            title: "Find Pet-Friendly Places",
            subtitle: "Discover nearby vets, pet shops, parks, grooming stores, and safe places for your pet.",
            icon: "map.fill",
            accent: AppColors.primary,
            background: AppColors.lightOrange
        ),
        .init(
            title: "Create Safe Walk Routes",
            subtitle: "Save your favorite walking paths, mark unsafe spots, and keep every walk stress-free.",
            icon: "figure.walk.circle.fill",
            accent: AppColors.secondary,
            background: AppColors.lightMint
        ),
        .init(
            title: "Lost Pet Alerts Nearby",
            subtitle: "Post lost pet alerts with location, photo details, and help your local pet community respond faster.",
            icon: "bell.badge.fill",
            accent: AppColors.danger,
            background: Color.red.opacity(0.10)
        )
    ]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            backgroundDecorations

            VStack(spacing: 0) {
                topBar

                TabView(selection: $selectedIndex) {
                    ForEach(pages.indices, id: \.self) { index in
                        onboardingPage(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomControls
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                animateContent = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(AppColors.primary)

                Text(AppConstants.appName)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Skip")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.75))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
    }

    private func onboardingPage(_ page: OnboardingPage) -> some View {
        GeometryReader { geo in
            VStack(spacing: geo.size.height < 620 ? 22 : 34) {
                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(page.background)
                        .frame(width: min(geo.size.width * 0.72, 280), height: min(geo.size.width * 0.72, 280))
                        .shadow(color: page.accent.opacity(0.18), radius: 28, x: 0, y: 18)

                    Circle()
                        .stroke(page.accent.opacity(0.18), lineWidth: 2)
                        .frame(width: min(geo.size.width * 0.58, 225), height: min(geo.size.width * 0.58, 225))

                    Image(systemName: page.icon)
                        .font(.system(size: min(geo.size.width * 0.22, 92), weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.accent, page.accent.opacity(0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateContent ? 1 : 0.75)
                        .rotationEffect(.degrees(animateContent ? 0 : -8))
                }

                VStack(spacing: 14) {
                    Text(page.title)
                        .font(.system(size: titleSize, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(page.subtitle)
                        .font(.system(size: subtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.softText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
                .offset(y: animateContent ? 0 : 18)
                .opacity(animateContent ? 1 : 0)

                Spacer(minLength: 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? pages[selectedIndex].accent : AppColors.softText.opacity(0.22))
                        .frame(width: index == selectedIndex ? 28 : 9, height: 9)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedIndex)
                }
            }

            Button {
                if selectedIndex == pages.count - 1 {
                    completeOnboarding()
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        selectedIndex += 1
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selectedIndex == pages.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 17, weight: .black, design: .rounded))

                    Image(systemName: selectedIndex == pages.count - 1 ? "pawprint.fill" : "arrow.right")
                        .font(.system(size: 16, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [pages[selectedIndex].accent, pages[selectedIndex].accent.opacity(0.75)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: pages[selectedIndex].accent.opacity(0.28), radius: 18, x: 0, y: 10)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
    }

    private var backgroundDecorations: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                    .frame(width: geo.size.width * 0.65)
                    .blur(radius: 32)
                    .offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.36)

                Circle()
                    .fill(AppColors.secondary.opacity(0.12))
                    .frame(width: geo.size.width * 0.72)
                    .blur(radius: 34)
                    .offset(x: geo.size.width * 0.38, y: geo.size.height * 0.36)
            }
        }
        .ignoresSafeArea()
    }

    private var titleSize: CGFloat {
        UIScreen.main.bounds.width <= 350 ? 28 : 34
    }

    private var subtitleSize: CGFloat {
        UIScreen.main.bounds.width <= 350 ? 15 : 17
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.35)) {
            hasCompletedOnboarding = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onComplete?()
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let background: Color
}

#Preview {
    OnboardingView()
}
