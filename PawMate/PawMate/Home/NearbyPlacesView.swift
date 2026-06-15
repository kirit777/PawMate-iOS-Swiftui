//
//  NearbyPlacesView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI
import MapKit
import CoreLocation

struct NearbyPlacesView: View {
    @Binding var path: NavigationPath

    @StateObject private var locationManager = PawLocationManager()
    @State private var selectedCategory: PetMapCategory = .vets
    @State private var places: [PetPlace] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedPlace: PetPlace?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: MapConstants.defaultLatitude,
                longitude: MapConstants.defaultLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: MapConstants.defaultSpan,
                longitudeDelta: MapConstants.defaultSpan
            )
        )
    )

    var filteredPlaces: [PetPlace] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return places
        }

        return places.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                categoryScroll

                mapView

                placesList
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            locationManager.requestLocation()
            searchNearbyPlaces()
        }
        .onChange(of: selectedCategory) { _, _ in
            searchNearbyPlaces()
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard let newLocation else { return }
            moveMap(to: newLocation.coordinate)
            searchNearbyPlaces()
        }
    }

    private var headerView: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Nearby Places")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)

                    Text("Find vets, parks, shops and pet services near you")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                }

                Spacer()

                Button {
                    locationManager.requestLocation()
                    if let coordinate = locationManager.userLocation?.coordinate {
                        moveMap(to: coordinate)
                        searchNearbyPlaces()
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
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

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.softText)

                TextField("Search places", text: $searchText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PetMapCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14, weight: .black))

                            Text(category.title)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                        }
                        .foregroundColor(selectedCategory == category ? .white : AppColors.darkText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(selectedCategory == category ? category.color : AppColors.card)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition, selection: $selectedPlace) {
            UserAnnotation()

            ForEach(places) { place in
                Marker(place.name, systemImage: place.category.icon, coordinate: place.coordinate)
                    .tint(place.category.color)
                    .tag(place)
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.32)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 18)
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        .onChange(of: selectedPlace) { _, newPlace in
            guard let newPlace else { return }
            path.append(AppRoute.placeDetail(newPlace))
        }
    }

    private var placesList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isLoading ? "Searching..." : "\(filteredPlaces.count) places found")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(AppColors.primary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if filteredPlaces.isEmpty && !isLoading {
                        emptyState
                    } else {
                        ForEach(filteredPlaces) { place in
                            placeRow(place)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
    }

    private func placeRow(_ place: PetPlace) -> some View {
        Button {
            path.append(AppRoute.placeDetail(place))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: place.category.icon)
                    .font(.system(size: 19, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(place.category.color)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                        .lineLimit(1)

                    Text(place.address)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                        .lineLimit(2)

                    Text(place.distanceText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(place.category.color)
                }

                Spacer()

                Button {
                    path.append(AppRoute.routeDirection(place))
                } label: {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(place.category.color)
                        .frame(width: 42, height: 42)
                        .background(place.category.color.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .padding(14)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 62))
                .foregroundColor(AppColors.primary)

            Text("No places found")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("Try another category or check location permission.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func searchNearbyPlaces() {
        isLoading = true

        let center = locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(
            latitude: MapConstants.defaultLatitude,
            longitude: MapConstants.defaultLongitude
        )

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = selectedCategory.searchQuery
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )

        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                let userLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

                self.places = response?.mapItems.prefix(20).map { item in
                    let coordinate = item.placemark.coordinate
                    let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let distance = userLocation.distance(from: placeLocation)

                    return PetPlace(
                        name: item.name ?? "Unknown Place",
                        category: selectedCategory,
                        address: formatAddress(item.placemark),
                        coordinate: coordinate,
                        distanceText: formatDistance(distance)
                    )
                } ?? []

                self.isLoading = false
            }
        }
    }

    private func moveMap(to coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )
        }
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String {
        [
            placemark.thoroughfare,
            placemark.subLocality,
            placemark.locality
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance)) m away"
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
}
