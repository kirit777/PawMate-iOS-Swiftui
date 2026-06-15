//
//  HomeMapView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import FirebaseDatabase
import UIKit


struct HomeMapView: View {
    @State private var path = NavigationPath()
    @StateObject private var locationManager = PawLocationManager()

    @State private var selectedCategory: PetMapCategory = .vets
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

    @State private var showCards = false
    @State private var isBottomPanelExpanded = false

    @State private var nearbyMapItems: [HomePetMapItem] = []
    @State private var isSearchingNearby = false
    @State private var selectedMapItem: HomePetMapItem?
    @State private var showPlaceSheet = false

    @State private var lostPetAlerts: [LostPetAlert] = []
    @State private var selectedLostPetAlert: LostPetAlert?
    @State private var showLostPetSheet = false

    @State private var savedWalkRoutes: [WalkRoute] = []

    @State private var weatherInfo: PawWeatherInfo?
    @State private var weeklyWeather: [PawDailyWeatherInfo] = []
    @State private var isLoadingWeather = false
    @State private var isWeatherExpanded = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(savedWalkRoutes) { route in
                        savedRouteMapContent(route)
                    }

                    ForEach(nearbyMapItems) { item in
                        Annotation(item.name, coordinate: item.coordinate) {
                            Button {
                                selectedMapItem = item
                                showPlaceSheet = true
                            } label: {
                                placeMarker(item)
                            }
                        }
                    }

                    ForEach(lostPetAlerts) { alert in
                        Annotation(alert.petName, coordinate: alert.coordinate) {
                            Button {
                                selectedLostPetAlert = alert
                                showLostPetSheet = true
                            } label: {
                                lostPetMarker(alert)
                            }
                        }
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader.padding(.top, 10)
                    categoryScroll
                    mapStatusBar
                    Spacer()
                    bottomPanel
                        .offset(y: showCards ? 0 : 120)
                        .opacity(showCards ? 1 : 0)
                }

                if isSearchingNearby {
                    ProgressView()
                        .tint(AppColors.primary)
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .nearbyPlaces:
                    NearbyPlacesView(path: $path)
                case .placeDetail(let place):
                    PlaceDetailView(place: place, path: $path)
                case .routeDirection(let place):
                    RouteDirectionView(place: place)
                case .myPets:
                    MyPetsView()
                case .safeWalkRoutes:
                    SafeWalkRoutesView(path: $path)
                case .lostPetAlerts:
                    LostPetAlertsView(path: $path)
                case .lostPetAlertDetail(let alertId):
                    LostPetAlertDetailView(alertId: alertId, path: $path)
                case .createLostPetAlert:
                    CreateLostPetAlertView()
                case .petCareReminders:
                    PetCareRemindersView(path: $path)
                case .createPetReminder:
                    CreatePetReminderView()
                case .petReminderDetail(let reminderId):
                    PetReminderDetailView(reminderId: reminderId, path: $path)
                case .settings:
                    SettingsView()
                case .createWalkRoute:
                    CreateWalkRouteView()
                case .walkRouteDetail(let routeId):
                    WalkRouteDetailView(routeId: routeId, path: $path)
                }
            }
            .sheet(isPresented: $showPlaceSheet) {
                if let selectedMapItem {
                    placeBottomSheet(selectedMapItem)
                        .presentationDetents([.height(260)])
                        .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showLostPetSheet) {
                if let selectedLostPetAlert {
                    lostPetBottomSheet(selectedLostPetAlert)
                        .presentationDetents([.height(360)])
                        .presentationDragIndicator(.visible)
                }
            }
            .onAppear {
                locationManager.requestLocation()
                searchNearbyPlaces()
                observeLostPetAlerts()
                fetchWeather()
                loadSavedWalkRoutes()

                withAnimation(.spring(response: 0.7, dampingFraction: 0.82).delay(0.2)) {
                    showCards = true
                }
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                guard let newLocation else { return }
                moveTo(newLocation.coordinate)
                searchNearbyPlaces()
                fetchWeather()
            }
            .onChange(of: path) { _, _ in
                loadSavedWalkRoutes()
            }
        }
    }

    @MapContentBuilder
    private func savedRouteMapContent(_ route: WalkRoute) -> some MapContent {
        if route.routeType.lowercased() == "route" {
            let start = CLLocationCoordinate2D(latitude: route.startLatitude, longitude: route.startLongitude)
            let end = CLLocationCoordinate2D(latitude: route.endLatitude, longitude: route.endLongitude)

            MapPolyline(coordinates: [start, end])
                .stroke(route.color, lineWidth: 5)

            Annotation("\(route.name) Start", coordinate: start) {
                Button {
                    path.append(AppRoute.walkRouteDetail(route.id.uuidString))
                } label: {
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(route.color)
                        .background(Color.white.clipShape(Circle()))
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
            }

            Annotation("\(route.name) End", coordinate: end) {
                Button {
                    path.append(AppRoute.walkRouteDetail(route.id.uuidString))
                } label: {
                    Image(systemName: "flag.checkered.circle.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(route.color)
                        .background(Color.white.clipShape(Circle()))
                        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
            }
        } else {
            let placeCoordinate = CLLocationCoordinate2D(latitude: route.startCoordinate.latitude, longitude: route.startCoordinate.longitude)

            Annotation(route.name, coordinate: placeCoordinate) {
                Button {
                    path.append(AppRoute.walkRouteDetail(route.id.uuidString))
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: route.icon)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(route.color)
                            .clipShape(Circle())

                        Text(route.name)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.darkText)
                            .lineLimit(1)
                            .frame(width: 90)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.92))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func placeMarker(_ item: HomePetMapItem) -> some View {
        VStack(spacing: 4) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(selectedCategory.color)
                .clipShape(Circle())

            Text(item.name)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)
                .lineLimit(1)
                .frame(width: 90)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.92))
                .clipShape(Capsule())
        }
    }

    private func lostPetMarker(_ alert: LostPetAlert) -> some View {
        VStack(spacing: 4) {
            Image(systemName: alert.mapIcon)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(AppColors.danger)
                .clipShape(Circle())

            Text("LOST")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(AppColors.danger)
                .clipShape(Capsule())
        }
    }

    private var topHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, Pet Parent")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.softText)

                    Text("Explore nearby pet places")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Button { path.append(AppRoute.lostPetAlerts) } label: {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.danger)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Circle())
                }

                Button { path.append(AppRoute.myPets) } label: {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Circle())
                }

                Button {
                    locationManager.requestLocation()
                    if let coordinate = locationManager.userLocation?.coordinate {
                        moveTo(coordinate)
                        searchNearbyPlaces()
                        fetchWeather()
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
            }

            weatherCard
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 16)
    }

    private var weatherCard: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isWeatherExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    if isLoadingWeather {
                        ProgressView()
                            .tint(AppColors.primary)
                            .frame(width: 42, height: 42)
                    } else {
                        Image(systemName: weatherInfo?.icon ?? "cloud.sun.fill")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(weatherInfo?.walkColor ?? AppColors.primary)
                            .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(weatherInfo?.title ?? "Checking weather...")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.darkText)

                        Text(weatherInfo?.message ?? "Finding if it is safe for pet walk.")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softText)
                            .lineLimit(2)
                    }

                    Spacer()

                    if let weatherInfo {
                        Text("\(Int(weatherInfo.temperature))°C")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(weatherInfo.walkColor)
                    }

                    Image(systemName: isWeatherExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(AppColors.primary)
                }
            }

            if isWeatherExpanded {
                weeklyWeatherView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weeklyWeatherView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Walk Report")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Spacer()

                if let bestDay = weeklyWeather.max(by: { $0.walkScore < $1.walkScore }) {
                    Text("Best: \(bestDay.dayName)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.primary)
                        .clipShape(Capsule())
                }
            }

            if weeklyWeather.isEmpty {
                Text("Weekly forecast not available right now.")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            } else {
                VStack(spacing: 8) {
                    ForEach(weeklyWeather) { day in
                        HStack(spacing: 10) {
                            Image(systemName: day.icon)
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(day.color)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(day.dayName)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(AppColors.darkText)

                                Text(day.walkMessage)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(AppColors.softText)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(Int(day.minTemp))° / \(Int(day.maxTemp))°")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundColor(day.color)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PetMapCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        searchNearbyPlaces()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                            Text(category.title)
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(selectedCategory == category ? .white : AppColors.darkText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(selectedCategory == category ? category.color : Color.white.opacity(0.88))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    private var mapStatusBar: some View {
        HStack(spacing: 10) {
            Text(isSearchingNearby ? "Searching \(selectedCategory.title)..." : "\(nearbyMapItems.count) \(selectedCategory.title) found")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(selectedCategory.color)
                .clipShape(Capsule())

            Button { focusLostPets() } label: {
                Text("\(lostPetAlerts.count) Lost")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.danger)
                    .clipShape(Capsule())
            }

            Button { focusSavedRoutes() } label: {
                Text("\(savedWalkRoutes.count) Routes")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppColors.secondary)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var bottomPanel: some View {
        VStack(spacing: isBottomPanelExpanded ? 14 : 10) {
            Capsule()
                .fill(AppColors.softText.opacity(0.35))
                .frame(width: 46, height: 5)

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isBottomPanelExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PawMate Hub")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.darkText)

                        Text(isBottomPanelExpanded ? "Tap to collapse" : "Tap to open quick actions")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softText)
                    }

                    Spacer()

                    Image(systemName: isBottomPanelExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(AppColors.primary)
                }
            }

            if isBottomPanelExpanded {
                Button {
                    path.append(AppRoute.nearbyPlaces)
                } label: {
                    Text("View All Nearby Places")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    quickActionCard(title: "My Pets", subtitle: "Manage pets", icon: "pawprint.fill", color: AppColors.primary, route: .myPets)
                    quickActionCard(title: "Safe Walk", subtitle: "Saved routes", icon: "figure.walk", color: AppColors.secondary, route: .safeWalkRoutes)
                    quickActionCard(title: "Lost Pet", subtitle: "Live alerts", icon: "bell.badge.fill", color: AppColors.danger, route: .lostPetAlerts)
                    quickActionCard(title: "Care", subtitle: "Reminders", icon: "calendar.badge.clock", color: .purple, route: .petCareReminders)
                }
                Button {
                    path.append(AppRoute.settings)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.gray)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Settings")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(AppColors.darkText)
                            
                            Text("App preferences")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.softText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(AppColors.softText)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color, route: AppRoute) -> some View {
        Button {
            path.append(route)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(color)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func placeBottomSheet(_ item: HomePetMapItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(item.name)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text(item.address)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softText)

            Button {
                openInAppleMaps(item)
            } label: {
                Text("Open Route")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(20)
        .background(AppColors.card)
    }

    private func lostPetBottomSheet(_ alert: LostPetAlert) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(alert.petName)
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text(alert.lastSeenLocation)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text(alert.description)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softText)
                .lineLimit(3)

            Button {
                showLostPetSheet = false
                path.append(AppRoute.lostPetAlertDetail(alert.id.uuidString))
            } label: {
                Text("View Details")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.danger)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(20)
        .background(AppColors.card)
    }

    private func loadSavedWalkRoutes() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.walkRoutes),
              let routes = try? JSONDecoder().decode([WalkRoute].self, from: data) else {
            savedWalkRoutes = []
            return
        }

        savedWalkRoutes = routes
    }

    private func focusSavedRoutes() {
        guard let first = savedWalkRoutes.first else { return }

        if first.routeType.lowercased() == "route" {
            moveTo(CLLocationCoordinate2D(latitude: first.startLatitude, longitude: first.startLongitude))
        } else {
            moveTo(CLLocationCoordinate2D(latitude: first.startCoordinate.latitude, longitude: first.startCoordinate.longitude))
        }
    }

    private func fetchWeather() {
        isLoadingWeather = true

        let coordinate = locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(
            latitude: MapConstants.defaultLatitude,
            longitude: MapConstants.defaultLongitude
        )

        PawWeatherService.fetchWeather(latitude: coordinate.latitude, longitude: coordinate.longitude) { result in
            DispatchQueue.main.async {
                isLoadingWeather = false

                switch result {
                case .success(let response):
                    weatherInfo = response.current
                    weeklyWeather = response.weekly

                case .failure:
                    weatherInfo = PawWeatherInfo(
                        temperature: 0,
                        windSpeed: 0,
                        weatherCode: 0,
                        title: "Weather unavailable",
                        message: "Unable to check walk safety right now.",
                        icon: "exclamationmark.triangle.fill",
                        walkColor: AppColors.danger
                    )
                    weeklyWeather = []
                }
            }
        }
    }

    private func observeLostPetAlerts() {
        FirebaseLostPetService.shared.observeLostPetAlerts { alerts in
            DispatchQueue.main.async {
                self.lostPetAlerts = alerts
            }
        }
    }

    private func focusLostPets() {
        guard let first = lostPetAlerts.first else { return }
        moveTo(first.coordinate)
    }

    private func searchNearbyPlaces() {
        isSearchingNearby = true

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
                isSearchingNearby = false

                nearbyMapItems = response?.mapItems.prefix(20).map {
                    HomePetMapItem(
                        name: $0.name ?? selectedCategory.title,
                        address: $0.placemark.title ?? "Nearby location",
                        latitude: $0.placemark.coordinate.latitude,
                        longitude: $0.placemark.coordinate.longitude
                    )
                } ?? []

                if let first = nearbyMapItems.first {
                    moveTo(first.coordinate)
                }
            }
        }
    }

    private func openInAppleMaps(_ item: HomePetMapItem) {
        let sourceCoordinate = locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(
            latitude: MapConstants.defaultLatitude,
            longitude: MapConstants.defaultLongitude
        )

        let source = "\(sourceCoordinate.latitude),\(sourceCoordinate.longitude)"
        let destination = "\(item.coordinate.latitude),\(item.coordinate.longitude)"
        let urlString = "http://maps.apple.com/?saddr=\(source)&daddr=\(destination)&dirflg=w"

        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { return }

        UIApplication.shared.open(url)
    }

    private func moveTo(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.55)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: MapConstants.defaultSpan,
                        longitudeDelta: MapConstants.defaultSpan
                    )
                )
            )
        }
    }
}

#Preview {
    HomeMapView()
}

struct PawWeatherResponse {
    let current: PawWeatherInfo
    let weekly: [PawDailyWeatherInfo]
}

struct PawWeatherInfo {
    let temperature: Double
    let windSpeed: Double
    let weatherCode: Int
    let title: String
    let message: String
    let icon: String
    let walkColor: Color
}

struct PawDailyWeatherInfo: Identifiable {
    let id = UUID()
    let date: String
    let dayName: String
    let minTemp: Double
    let maxTemp: Double
    let weatherCode: Int
    let walkScore: Int
    let walkMessage: String
    let icon: String
    let color: Color
}

final class PawWeatherService {
    static func fetchWeather(latitude: Double, longitude: Double, completion: @escaping (Result<PawWeatherResponse, Error>) -> Void) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=7&timezone=auto"

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid weather URL", code: 0)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data,
                  let decoded = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data) else {
                completion(.failure(NSError(domain: "Weather decode failed", code: 0)))
                return
            }

            let current = makePetWalkInfo(
                temp: decoded.current.temperature2m,
                wind: decoded.current.windSpeed10m,
                code: decoded.current.weatherCode
            )

            let weekly = decoded.daily.time.indices.map { index in
                makeDailyInfo(
                    date: decoded.daily.time[index],
                    minTemp: decoded.daily.temperature2mMin[index],
                    maxTemp: decoded.daily.temperature2mMax[index],
                    code: decoded.daily.weatherCode[index]
                )
            }

            completion(.success(PawWeatherResponse(current: current, weekly: weekly)))
        }.resume()
    }

    private static func makeDailyInfo(date: String, minTemp: Double, maxTemp: Double, code: Int) -> PawDailyWeatherInfo {
        let rainyCodes = [51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99]
        let isRainy = rainyCodes.contains(code)

        let score: Int
        let message: String
        let icon: String
        let color: Color

        if maxTemp >= 35 {
            score = 30
            message = "Too hot, avoid long walk"
            icon = "sun.max.fill"
            color = AppColors.danger
        } else if minTemp <= 8 {
            score = 35
            message = "Too cold, short walk only"
            icon = "snowflake"
            color = AppColors.danger
        } else if isRainy {
            score = 55
            message = "Rain chance, not ideal"
            icon = "cloud.rain.fill"
            color = .orange
        } else {
            score = 90
            message = "Good day for pet walk"
            icon = "cloud.sun.fill"
            color = AppColors.primary
        }

        return PawDailyWeatherInfo(
            date: date,
            dayName: dayName(from: date),
            minTemp: minTemp,
            maxTemp: maxTemp,
            weatherCode: code,
            walkScore: score,
            walkMessage: message,
            icon: icon,
            color: color
        )
    }

    private static func makePetWalkInfo(temp: Double, wind: Double, code: Int) -> PawWeatherInfo {
        let isRainy = [51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99].contains(code)

        if temp >= 35 {
            return PawWeatherInfo(
                temperature: temp,
                windSpeed: wind,
                weatherCode: code,
                title: "Not good for walk",
                message: "Too hot for pets. Avoid outdoor walk now.",
                icon: "sun.max.fill",
                walkColor: AppColors.danger
            )
        } else if temp <= 8 {
            return PawWeatherInfo(
                temperature: temp,
                windSpeed: wind,
                weatherCode: code,
                title: "Not good for walk",
                message: "Too cold for pets. Keep walk short.",
                icon: "snowflake",
                walkColor: AppColors.danger
            )
        } else if isRainy {
            return PawWeatherInfo(
                temperature: temp,
                windSpeed: wind,
                weatherCode: code,
                title: "Not ideal for walk",
                message: "Rainy weather. Carry protection or wait.",
                icon: "cloud.rain.fill",
                walkColor: .orange
            )
        } else if wind > 35 {
            return PawWeatherInfo(
                temperature: temp,
                windSpeed: wind,
                weatherCode: code,
                title: "Be careful outside",
                message: "Wind is strong. Short walk is better.",
                icon: "wind",
                walkColor: .orange
            )
        } else {
            return PawWeatherInfo(
                temperature: temp,
                windSpeed: wind,
                weatherCode: code,
                title: "Good for pet walk",
                message: "Weather looks comfortable for a walk.",
                icon: "cloud.sun.fill",
                walkColor: AppColors.primary
            )
        }
    }

    private static func dayName(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let output = DateFormatter()
        output.dateFormat = "EEE"
        return output.string(from: date)
    }
}

struct OpenMeteoResponse: Codable {
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
}

struct OpenMeteoCurrent: Codable {
    let temperature2m: Double
    let weatherCode: Int
    let windSpeed10m: Double

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }
}

struct OpenMeteoDaily: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
    }
}

struct HomePetMapItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

final class PawLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
}

enum PetMapCategory: String, CaseIterable, Identifiable {
    case vets
    case petShops
    case parks
    case grooming
    case shelters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vets: return "Vets"
        case .petShops: return "Pet Shops"
        case .parks: return "Parks"
        case .grooming: return "Grooming"
        case .shelters: return "Shelters"
        }
    }

    var searchQuery: String {
        switch self {
        case .vets: return "veterinary clinic"
        case .petShops: return "pet shop"
        case .parks: return "dog park"
        case .grooming: return "pet grooming"
        case .shelters: return "animal shelter"
        }
    }

    var icon: String {
        switch self {
        case .vets: return "cross.case.fill"
        case .petShops: return "cart.fill"
        case .parks: return "tree.fill"
        case .grooming: return "scissors"
        case .shelters: return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .vets: return AppColors.primary
        case .petShops: return AppColors.secondary
        case .parks: return .green
        case .grooming: return .purple
        case .shelters: return .blue
        }
    }
}


#Preview {
    HomeMapView()
}
