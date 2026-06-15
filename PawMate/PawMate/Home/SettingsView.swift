//
//  SettingsView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = true

    @State private var showResetAlert = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerView
                    appInfoCard
                    dataCard
                    resetCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .alert("Reset PawMate?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAppData()
            }
        } message: {
            Text("This will delete pets, walk routes, lost pet alerts and reminders from this device.")
        }
    }

    private var headerView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.14))
                    .frame(width: 120, height: 120)

                Image("iconApp")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 92)
                    .clipShape(Circle())
                    .shadow(color: AppColors.primary.opacity(0.18), radius: 14, x: 0, y: 8)
            }

            VStack(spacing: 6) {
                Text("PawMate")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Your local pet care companion")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(animateContent ? 1 : 0.94)
        .opacity(animateContent ? 1 : 0)
    }

    private var appInfoCard: some View {
        VStack(spacing: 12) {
            settingsRow(
                title: "App Name",
                subtitle: "PawMate",
                icon: "pawprint.fill",
                color: AppColors.primary
            )

            settingsRow(
                title: "Storage",
                subtitle: "All data is saved locally on this iPhone",
                icon: "iphone",
                color: AppColors.secondary
            )

            settingsRow(
                title: "Maps",
                subtitle: "Uses Apple Maps and device location",
                icon: "map.fill",
                color: .green
            )
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var dataCard: some View {
        VStack(spacing: 12) {
            settingsRow(
                title: "My Pets",
                subtitle: "\(countItems(for: AppStorageKeys.myPets)) saved",
                icon: "heart.fill",
                color: .pink
            )

            settingsRow(
                title: "Walk Routes",
                subtitle: "\(countItems(for: AppStorageKeys.walkRoutes)) saved",
                icon: "figure.walk",
                color: AppColors.primary
            )

            settingsRow(
                title: "Lost Pet Alerts",
                subtitle: "\(countItems(for: AppStorageKeys.lostPetAlerts)) saved",
                icon: "bell.badge.fill",
                color: AppColors.danger
            )

            settingsRow(
                title: "Care Reminders",
                subtitle: "\(countItems(for: AppStorageKeys.petCareReminders)) saved",
                icon: "calendar.badge.clock",
                color: AppColors.secondary
            )
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var resetCard: some View {
        VStack(spacing: 12) {
            Button {
                hasCompletedOnboarding = false
            } label: {
                settingsButton(
                    title: "Show Onboarding Again",
                    icon: "sparkles",
                    color: AppColors.primary
                )
            }

            Button {
                showResetAlert = true
            } label: {
                settingsButton(
                    title: "Reset All Local Data",
                    icon: "trash.fill",
                    color: AppColors.danger
                )
            }
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func settingsRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func settingsButton(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(AppColors.softText.opacity(0.7))
        }
        .padding(12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var backgroundDecorations: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.10))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 35)
                    .offset(x: -geo.size.width * 0.35, y: -geo.size.height * 0.32)

                Circle()
                    .fill(AppColors.secondary.opacity(0.10))
                    .frame(width: geo.size.width * 0.72)
                    .blur(radius: 35)
                    .offset(x: geo.size.width * 0.36, y: geo.size.height * 0.34)
            }
        }
    }

    private func countItems(for key: String) -> Int {
        guard let data = UserDefaults.standard.data(forKey: key),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            return 0
        }

        return array.count
    }

    private func resetAppData() {
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.myPets)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.walkRoutes)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.lostPetAlerts)
        UserDefaults.standard.removeObject(forKey: AppStorageKeys.petCareReminders)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
