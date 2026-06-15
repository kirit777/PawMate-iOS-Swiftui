//
//  PlaceDetailView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct PlaceDetailView: View {
    let place: PetPlace
    @Binding var path: NavigationPath

    @StateObject private var locationManager = PawLocationManager()

    @State private var cameraPosition: MapCameraPosition
    @State private var animateContent = false
    @State private var toastMessage = ""
    @State private var showToast = false

    init(place: PetPlace, path: Binding<NavigationPath>) {
        self.place = place
        self._path = path
        self._cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: place.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            )
        )
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    mapCard
                    detailCard
                    actionButtons
                    infoCards
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }

            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .navigationTitle("Place Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestLocation()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
    }

    private var mapCard: some View {
        ZStack(alignment: .bottomLeading) {
            Map(position: $cameraPosition) {
                Marker(place.name, systemImage: place.category.icon, coordinate: place.coordinate)
                    .tint(place.category.color)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            HStack(spacing: 10) {
                Image(systemName: place.category.icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(place.category.color)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.category.title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)

                    Text(place.distanceText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                }

                Spacer()
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(14)
        }
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
        .scaleEffect(animateContent ? 1 : 0.94)
        .opacity(animateContent ? 1 : 0)
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(place.name)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)
                .lineLimit(3)
                .minimumScaleFactor(0.8)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(place.category.color)

                Text(place.address.isEmpty ? "Address not available" : place.address)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .lineSpacing(3)
            }

            HStack(spacing: 10) {
                badge(title: place.category.title, icon: place.category.icon, color: place.category.color)
                badge(title: place.distanceText, icon: "location.fill", color: AppColors.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                path.append(AppRoute.routeDirection(place))
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    Text("Get Directions")
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
                .shadow(color: AppColors.primary.opacity(0.24), radius: 16, x: 0, y: 9)
            }

            Button {
                openInAppleMaps()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                    Text("Open Route in Apple Maps")
                }
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
            }
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var infoCards: some View {
        VStack(spacing: 12) {
            infoRow(
                title: "Community Safety",
                subtitle: "Check reviews and safety reports here in future update.",
                icon: "shield.lefthalf.filled",
                color: AppColors.secondary
            )

            infoRow(
                title: "Pet Friendly Note",
                subtitle: "You can later add ratings, photos, and pet-owner notes for this place.",
                icon: "pawprint.fill",
                color: AppColors.primary
            )
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
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

    private func badge(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .black))

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func infoRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var fallbackSourceCoordinate: CLLocationCoordinate2D {
        locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(
            latitude: MapConstants.defaultLatitude,
            longitude: MapConstants.defaultLongitude
        )
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
}
