//
//  SafeWalkRoutesView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct SafeWalkRoutesView: View {
    @Binding var path: NavigationPath

    @State private var routes: [WalkRoute] = []
    @State private var animateCards = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        statsCard

                        if routes.isEmpty {
                            emptyState
                        } else {
                            ForEach(routes) { route in
                                routeCard(route)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Safe Walk Routes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRoutes()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateCards = true
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Safe Walk Routes")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Save pet-friendly walking paths and unsafe spots")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()

            Button {
                path.append(AppRoute.createWalkRoute)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: AppColors.primary.opacity(0.25), radius: 14, x: 0, y: 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var statsCard: some View {
        HStack(spacing: 12) {
            statItem(
                title: "Routes",
                value: "\(routes.count)",
                icon: "map.fill",
                color: AppColors.primary
            )

            statItem(
                title: "Safe Spots",
                value: "\(routes.reduce(0) { $0 + $1.safeSpots })",
                icon: "checkmark.shield.fill",
                color: AppColors.secondary
            )
        }
        .scaleEffect(animateCards ? 1 : 0.94)
        .opacity(animateCards ? 1 : 0)
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

    private func routeCard(_ route: WalkRoute) -> some View {
        Button {
            path.append(AppRoute.walkRouteDetail(route.id.uuidString))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: route.icon)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(route.color)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(route.name)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)

                    Text("\(route.distance) • \(route.duration)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softText)

                    Text(route.note)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(route.color)
                        .lineLimit(1)
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 76))
                .foregroundColor(AppColors.secondary)

            Text("No Walk Routes Yet")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("Create your first safe walking route for your pet. Mark good paths, unsafe spots, and favorite areas.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                path.append(AppRoute.createWalkRoute)
            } label: {
                Text("Create Walk Route")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
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

    private func loadRoutes() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.walkRoutes),
              let savedRoutes = try? JSONDecoder().decode([WalkRoute].self, from: data) else {
            routes = []
            return
        }

        routes = savedRoutes
    }
}



struct WalkRoute: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let distance: String
    let duration: String
    let note: String
    let safeSpots: Int
    let routeType: String
    
    let startLatitude: Double
    let startLongitude: Double
    let endLatitude: Double
    let endLongitude: Double
    
    let startPlaceName: String
    let endPlaceName: String
    
    var icon: String {
        switch routeType {
        case "park": return "tree.fill"
        case "street": return "road.lanes"
        default: return "figure.walk"
        }
    }

    var color: Color {
        switch routeType {
        case "park": return .green
        case "street": return AppColors.primary
        default: return AppColors.secondary
        }
    }
}

#Preview {
    NavigationStack {
        SafeWalkRoutesView(path: .constant(NavigationPath()))
    }
}
