//
//  LostPetAlertsView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import UIKit
import FirebaseDatabase

struct LostPetAlertsView: View {
    @Binding var path: NavigationPath

    @State private var alerts: [LostPetAlert] = []
    @State private var animateCards = false
    @State private var isLoading = false

    @State private var toastMessage = ""
    @State private var showToast = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        summaryCard

                        if isLoading {
                            loadingView
                        } else if alerts.isEmpty {
                            emptyState
                        } else {
                            ForEach(alerts) { alert in
                                alertCard(alert)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }

            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .navigationTitle("Lost Pet Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            observeFirebaseAlerts()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateCards = true
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Lost Pet Alerts")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Live community alerts from Firebase")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()

            Button {
                observeFirebaseAlerts()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(AppColors.danger)
                    .frame(width: 48, height: 48)
                    .background(AppColors.card)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
            }

            Button {
                path.append(AppRoute.createLostPetAlert)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [AppColors.danger, AppColors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: AppColors.danger.opacity(0.25), radius: 14, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            statItem(
                title: "Active Alerts",
                value: "\(alerts.count)",
                icon: "bell.badge.fill",
                color: AppColors.danger
            )

            statItem(
                title: "Source",
                value: "Live",
                icon: "cloud.fill",
                color: AppColors.secondary
            )
        }
        .scaleEffect(animateCards ? 1 : 0.94)
        .opacity(animateCards ? 1 : 0)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(AppColors.danger)
                .scaleEffect(1.2)

            Text("Loading live lost pet alerts...")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(AppColors.softText)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func alertCard(_ alert: LostPetAlert) -> some View {
        Button {
            path.append(AppRoute.lostPetAlertDetail(alert.id.uuidString))
        } label: {
            HStack(spacing: 12) {
                petThumbnail(alert)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(alert.petName)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.darkText)
                            .lineLimit(1)

                        Text(alert.status)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.danger)
                            .clipShape(Capsule())
                    }

                    Text(alert.lastSeenLocation)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                        .lineLimit(1)

                    Text(alert.dateText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.danger)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(AppColors.softText.opacity(0.7))
            }
            .padding(14)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
    }

    private func petThumbnail(_ alert: LostPetAlert) -> some View {
        ZStack {
            if let imageBase64 = alert.imageBase64,
               let data = Data(base64Encoded: imageBase64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Image(systemName: petIcon(alert.petType))
                    .font(.system(size: 21, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AppColors.danger)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.badge.circle.fill")
                .font(.system(size: 76))
                .foregroundColor(AppColors.danger)

            Text("No Lost Pet Alerts")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("Create an alert if your pet is missing. Other PawMate users can see it live on the home map.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                path.append(AppRoute.createLostPetAlert)
            } label: {
                Text("Create Lost Pet Alert")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [AppColors.danger, AppColors.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
    }

    private var toastView: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.white)

                Text(toastMessage)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(AppColors.darkText.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer()
        }
    }

    private var backgroundDecorations: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppColors.danger.opacity(0.10))
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

    private func petIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        default: return "pawprint.fill"
        }
    }

    private func observeFirebaseAlerts() {
        isLoading = true

        FirebaseLostPetService.shared.observeLostPetAlerts { firebaseAlerts in
            DispatchQueue.main.async {
                self.isLoading = false
                self.alerts = firebaseAlerts.sorted { $0.dateText > $1.dateText }
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
            }
        }
    }
}
