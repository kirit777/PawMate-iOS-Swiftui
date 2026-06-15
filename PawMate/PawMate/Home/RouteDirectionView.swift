//
//  RouteDirectionView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct RouteDirectionView: View {
    let place: PetPlace

    @StateObject private var locationManager = PawLocationManager()

    @State private var cameraPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var isLoadingRoute = false
    @State private var routeError: String?
    @State private var animateContent = false

    @State private var toastMessage = ""
    @State private var showToast = false

    init(place: PetPlace) {
        self.place = place
        self._cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: place.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
                )
            )
        )
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                mapView
                bottomSheet
            }

            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .navigationTitle("Directions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestLocation()
            calculateRoute(from: fallbackSourceCoordinate)

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard let newLocation else { return }
            calculateRoute(from: newLocation.coordinate)
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            Annotation("Start", coordinate: fallbackSourceCoordinate) {
                mapPin(icon: "location.fill", color: AppColors.primary)
            }

            Marker(place.name, systemImage: place.category.icon, coordinate: place.coordinate)
                .tint(place.category.color)

            if let route {
                MapPolyline(route.polyline)
                    .stroke(AppColors.primary, lineWidth: 6)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
        .ignoresSafeArea(edges: .top)
    }

    private var bottomSheet: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppColors.softText.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            placeHeader

            if isLoadingRoute {
                loadingView
            } else if let route {
                routeInfo(route)
            } else if let routeError {
                errorView(routeError)
            } else {
                permissionView
            }

            actionButtons
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: -8)
        .offset(y: animateContent ? 0 : 140)
        .opacity(animateContent ? 1 : 0)
    }

    private var placeHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: place.category.icon)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(place.category.color)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                    .lineLimit(2)

                Text(place.address.isEmpty ? "Address not available" : place.address)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primary)

            Text("Finding walking route...")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softText)

            Spacer()
        }
        .padding(14)
        .background(AppColors.card.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func routeInfo(_ route: MKRoute) -> some View {
        HStack(spacing: 12) {
            routeMetricCard(
                title: "Distance",
                value: formatDistance(route.distance),
                icon: "location.fill",
                color: AppColors.primary
            )

            routeMetricCard(
                title: "Time",
                value: formatTime(route.expectedTravelTime),
                icon: "clock.fill",
                color: AppColors.secondary
            )
        }
    }

    private func routeMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)

                Text(value)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }

            Spacer()
        }
        .padding(12)
        .background(AppColors.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(AppColors.danger)
                .clipShape(Circle())

            Text(message)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softText)
                .lineLimit(3)

            Spacer()
        }
        .padding(14)
        .background(AppColors.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var permissionView: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(AppColors.primary)
                .clipShape(Circle())

            Text("Showing route from default/current location. Enable location for exact route.")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softText)
                .lineLimit(3)

            Spacer()
        }
        .padding(14)
        .background(AppColors.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                openInAppleMaps()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                    Text("Start in Apple Maps")
                }
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            }

            Button {
                locationManager.requestLocation()
                calculateRoute(from: fallbackSourceCoordinate)
            } label: {
                Text("Refresh Route")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.card.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            }
        }
    }

    private var toastView: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 17, weight: .black))
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
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
            .padding(.horizontal, 18)
            .padding(.top, 12)

            Spacer()
        }
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

    private var fallbackSourceCoordinate: CLLocationCoordinate2D {
        locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(
            latitude: MapConstants.defaultLatitude,
            longitude: MapConstants.defaultLongitude
        )
    }

    private func calculateRoute(from sourceCoordinate: CLLocationCoordinate2D) {
        isLoadingRoute = true
        routeError = nil

        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: sourceCoordinate)
        )
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: place.coordinate)
        )
        request.transportType = .walking
        request.requestsAlternateRoutes = true

        MKDirections(request: request).calculate { response, error in
            DispatchQueue.main.async {
                self.isLoadingRoute = false

                if let error {
                    self.route = nil
                    self.routeError = error.localizedDescription
                    self.showToastMessage(error.localizedDescription)
                    return
                }

                guard let route = response?.routes.first else {
                    self.route = nil
                    self.routeError = "Walking route not available for this place."
                    self.showToastMessage("Walking route not available.")
                    return
                }

                self.route = route
                self.routeError = nil
                self.fitMapToRoute(route)

                if self.locationManager.userLocation == nil {
                    self.showToastMessage("Location not available. Showing route from default location.")
                }
            }
        }
    }

    private func fitMapToRoute(_ route: MKRoute) {
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .rect(route.polyline.boundingMapRect)
        }
    }

    private func openInAppleMaps() {
        let sourceCoordinate = fallbackSourceCoordinate
        let source = "\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)"
        let destination = "\(place.coordinate.latitude),\(place.coordinate.longitude)"

        let urlString = "http://maps.apple.com/?saddr=\(source)&daddr=\(destination)&dirflg=w"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            showToastMessage("Unable to open Apple Maps.")
            return
        }

        UIApplication.shared.open(url) { success in
            if !success {
                showToastMessage("Apple Maps could not be opened.")
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

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m"
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int(seconds / 60))

        if minutes < 60 {
            return "\(minutes) min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "\(hours) hr"
        }

        return "\(hours) hr \(remainingMinutes) min"
    }
}
