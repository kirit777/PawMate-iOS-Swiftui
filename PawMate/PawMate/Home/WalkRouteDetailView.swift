//
//  WalkRouteDetailView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct WalkRouteDetailView: View {
    let routeId: String
    @Binding var path: NavigationPath

    @State private var route: WalkRoute?
    @State private var showDeleteAlert = false
    @State private var animateContent = false
    @State private var calculatedRoute: MKRoute?

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: MapConstants.defaultLatitude,
                longitude: MapConstants.defaultLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
        )
    )

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            if let route {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard(route)
                        routeMapCard(route)
                        routeStats(route)
                        safetyNoteCard(route)
                        actionButtons(route)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                }
            } else {
                notFoundView
            }
        }
        .navigationTitle("Route Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadRoute()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .onChange(of: route) { _, newRoute in
            guard let newRoute else { return }
            focusRoute(newRoute)
            calculateRoute(newRoute)
        }
        .alert("Delete Route?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRoute()
            }
        } message: {
            Text("This walk route will be removed from PawMate.")
        }
    }

    private func heroCard(_ route: WalkRoute) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(route.color.opacity(0.14))
                    .frame(width: 130, height: 130)

                Circle()
                    .stroke(route.color.opacity(0.24), lineWidth: 2)
                    .frame(width: 108, height: 108)

                Image(systemName: route.icon)
                    .font(.system(size: 58, weight: .black))
                    .foregroundColor(route.color)
            }

            VStack(spacing: 6) {
                Text(route.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                    .multilineTextAlignment(.center)

                Text(route.routeType.capitalized + " Route")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(route.color)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .scaleEffect(animateContent ? 1 : 0.94)
        .opacity(animateContent ? 1 : 0)
    }

    private func routeMapCard(_ route: WalkRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Route Map")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Spacer()

                Button {
                    focusRoute(route)
                } label: {
                    Image(systemName: "scope")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(AppColors.primary)
                        .clipShape(Circle())
                }
            }

            Map(position: $cameraPosition) {
                Annotation(route.startPlaceName, coordinate: route.startCoordinate) {
                    mapPin(icon: "location.fill", color: AppColors.primary)
                }

                Annotation(route.endPlaceName, coordinate: route.endCoordinate) {
                    mapPin(icon: "flag.fill", color: AppColors.danger)
                }

                if let calculatedRoute {
                    MapPolyline(calculatedRoute.polyline)
                        .stroke(AppColors.secondary, lineWidth: 6)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func routeStats(_ route: WalkRoute) -> some View {
        HStack(spacing: 12) {
            statCard(
                title: "Distance",
                value: route.distance,
                icon: "location.fill",
                color: AppColors.primary
            )

            statCard(
                title: "Duration",
                value: route.duration,
                icon: "clock.fill",
                color: AppColors.secondary
            )
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(color)
                .clipShape(Circle())

            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softText)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func safetyNoteCard(_ route: WalkRoute) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(route.color)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Safety Note")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)

                    Text("\(route.safeSpots) safe spots marked")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                }

                Spacer()
            }

            Text(route.note)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softText)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func actionButtons(_ route: WalkRoute) -> some View {
        VStack(spacing: 12) {
            Button {
                openRouteInAppleMaps(route)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                    Text("Open Route Map")
                }
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            Button {
                showDeleteAlert = true
            } label: {
                Text("Delete Route")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var notFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70, weight: .black))
                .foregroundColor(AppColors.danger)

            Text("Route Not Found")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("This route may have been deleted.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softText)

            Button {
                path.removeLast()
            } label: {
                Text("Go Back")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 160, height: 52)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .padding(24)
    }

    private func mapPin(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white)
            .frame(width: 42, height: 42)
            .background(color)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
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

    private func loadRoute() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.walkRoutes),
              let routes = try? JSONDecoder().decode([WalkRoute].self, from: data) else {
            route = nil
            return
        }

        route = routes.first { $0.id.uuidString == routeId }
    }

    private func calculateRoute(_ route: WalkRoute) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: route.startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: route.endCoordinate))
        request.transportType = .walking

        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                calculatedRoute = response?.routes.first
            }
        }
    }

    private func focusRoute(_ route: WalkRoute) {
        let centerLatitude = (route.startLatitude + route.endLatitude) / 2
        let centerLongitude = (route.startLongitude + route.endLongitude) / 2

        let latitudeDelta = max(abs(route.startLatitude - route.endLatitude) * 2.4, 0.018)
        let longitudeDelta = max(abs(route.startLongitude - route.endLongitude) * 2.4, 0.018)

        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
                    span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                )
            )
        }
    }

    private func openRouteInAppleMaps(_ route: WalkRoute) {
        let start = "\(route.startLatitude),\(route.startLongitude)"
        let end = "\(route.endLatitude),\(route.endLongitude)"

        let urlString = "http://maps.apple.com/?saddr=\(start)&daddr=\(end)&dirflg=w"

        guard let url = URL(string: urlString) else { return }

        UIApplication.shared.open(url)
    }

    private func deleteRoute() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.walkRoutes),
              var routes = try? JSONDecoder().decode([WalkRoute].self, from: data) else {
            return
        }

        routes.removeAll { $0.id.uuidString == routeId }

        if let encoded = try? JSONEncoder().encode(routes) {
            UserDefaults.standard.set(encoded, forKey: AppStorageKeys.walkRoutes)
        }

        path.removeLast()
    }
}

extension WalkRoute {
    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

//    var icon: String {
//        switch routeType {
//        case "park": return "tree.fill"
//        case "street": return "road.lanes"
//        default: return "figure.walk"
//        }
//    }
//
//    var color: Color {
//        switch routeType {
//        case "park": return .green
//        case "street": return AppColors.primary
//        default: return AppColors.secondary
//        }
//    }
}

#Preview {
    NavigationStack {
        WalkRouteDetailView(routeId: UUID().uuidString, path: .constant(NavigationPath()))
    }
}
