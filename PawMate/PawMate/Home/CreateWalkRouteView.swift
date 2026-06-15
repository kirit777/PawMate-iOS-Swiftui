import SwiftUI
import MapKit
import CoreLocation

struct CreateWalkRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = PawLocationManager()

    @State private var routeName = ""
    @State private var note = ""
    @State private var selectedType: WalkRouteType = .park
    @State private var safeSpots = 1
    @State private var showValidation = false
    @State private var animateContent = false

    @State private var selectionMode: RoutePointSelectionMode = .start

    @State private var startLatitude = MapConstants.defaultLatitude
    @State private var startLongitude = MapConstants.defaultLongitude
    @State private var endLatitude = MapConstants.defaultLatitude + 0.006
    @State private var endLongitude = MapConstants.defaultLongitude + 0.006

    @State private var routeDistance = "Not calculated"
    @State private var routeDuration = "Not calculated"
    @State private var calculatedRoute: MKRoute?

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: MapConstants.defaultLatitude,
                longitude: MapConstants.defaultLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    )

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                    routeTypeCard
                    routeMapCard
                    formCard
                    saveButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Create Walk Route")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestLocation()
            calculateRoute()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard let coordinate = newLocation?.coordinate else { return }

            startLatitude = coordinate.latitude
            startLongitude = coordinate.longitude
            endLatitude = coordinate.latitude + 0.006
            endLongitude = coordinate.longitude + 0.006

            moveCamera(to: coordinate)
            calculateRoute()
        }
    }

    private var headerView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(selectedType.color.opacity(0.14))
                    .frame(width: 116, height: 116)

                Circle()
                    .stroke(selectedType.color.opacity(0.22), lineWidth: 2)
                    .frame(width: 94, height: 94)

                Image(systemName: selectedType.icon)
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(selectedType.color)
            }

            VStack(spacing: 6) {
                Text("Create Safe Route")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Select start and end points to create a real walking route.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(animateContent ? 1 : 0.92)
        .opacity(animateContent ? 1 : 0)
    }

    private var routeTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Route Type")

            HStack(spacing: 10) {
                ForEach(WalkRouteType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedType = type
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.system(size: 22, weight: .black))

                            Text(type.title)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                        }
                        .foregroundColor(selectedType == type ? .white : AppColors.darkText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 86)
                        .background(selectedType == type ? type.color : AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var routeMapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Select Route Points")

            HStack(spacing: 10) {
                selectionButton(title: "Start Point", mode: .start, icon: "location.circle.fill")
                selectionButton(title: "End Point", mode: .end, icon: "mappin.circle.fill")
            }

            MapReader { proxy in
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    Annotation("Start", coordinate: startCoordinate) {
                        routePin(icon: "location.fill", color: AppColors.primary)
                    }

                    Annotation("End", coordinate: endCoordinate) {
                        routePin(icon: "flag.fill", color: AppColors.danger)
                    }

                    if let calculatedRoute {
                        MapPolyline(calculatedRoute.polyline)
                            .stroke(AppColors.secondary, lineWidth: 6)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        updateSelectedPoint(coordinate)
                    }
                }
            }

            HStack(spacing: 10) {
                routeInfoChip(title: routeDistance, icon: "point.topleft.down.curvedto.point.bottomright.up")
                routeInfoChip(title: routeDuration, icon: "clock.fill")
            }

            Button {
                useCurrentLocationAsStart()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text("Use Current Location as Start")
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Text("Tip: Select Start Point or End Point, then tap on map.")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softText)
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var formCard: some View {
        VStack(spacing: 18) {
            inputField(
                title: "Route Name",
                placeholder: "Evening Park Walk",
                text: $routeName,
                icon: "map.fill"
            )

            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Safety Note")

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 22)
                        .padding(.top, 3)

                    TextField("Good lights, less traffic, water spot nearby...", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                }
                .padding(14)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                fieldTitle("Safe Spots")

                Stepper(value: $safeSpots, in: 0...20) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(AppColors.secondary)

                        Text("\(safeSpots) safe spots marked")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.darkText)
                    }
                }
                .padding(14)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if showValidation && !isFormValid {
                Text("Please fill route name and safety note.")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var saveButton: some View {
        Button {
            saveRoute()
        } label: {
            HStack(spacing: 10) {
                Text("Save Safe Route")
                    .font(.system(size: 17, weight: .black, design: .rounded))

                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .black))
            }
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
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func selectionButton(title: String, mode: RoutePointSelectionMode, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                selectionMode = mode
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundColor(selectionMode == mode ? .white : AppColors.darkText)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(selectionMode == mode ? mode.color : AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func routePin(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white)
            .frame(width: 42, height: 42)
            .background(color)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    private func routeInfoChip(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.system(size: 13, weight: .black, design: .rounded))
        .foregroundColor(AppColors.darkText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func inputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle(title)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 22)

                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundColor(AppColors.darkText)
    }

    private var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    private var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

    private func updateSelectedPoint(_ coordinate: CLLocationCoordinate2D) {
        if selectionMode == .start {
            startLatitude = coordinate.latitude
            startLongitude = coordinate.longitude
        } else {
            endLatitude = coordinate.latitude
            endLongitude = coordinate.longitude
        }

        moveCamera(to: coordinate)
        calculateRoute()
    }

    private func useCurrentLocationAsStart() {
        locationManager.requestLocation()

        if let coordinate = locationManager.userLocation?.coordinate {
            startLatitude = coordinate.latitude
            startLongitude = coordinate.longitude
            selectionMode = .end
            moveCamera(to: coordinate)
            calculateRoute()
        }
    }

    private func calculateRoute() {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))
        request.transportType = .walking

        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                guard let route = response?.routes.first else {
                    calculatedRoute = nil
                    routeDistance = "No route"
                    routeDuration = "No time"
                    return
                }

                calculatedRoute = route
                routeDistance = formattedDistance(route.distance)
                routeDuration = formattedDuration(route.expectedTravelTime)
            }
        }
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        } else {
            return "\(Int(meters)) m"
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = max(1, Int(seconds / 60))
        return "\(minutes) min"
    }

    private func moveCamera(to coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                )
            )
        }
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

    private var isFormValid: Bool {
        !routeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveRoute() {
        guard isFormValid else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showValidation = true
            }
            return
        }

        let cleanRouteName = routeName.trimmingCharacters(in: .whitespacesAndNewlines)

        let newRoute = WalkRoute(
            id: UUID(),
            name: cleanRouteName,
            distance: routeDistance,
            duration: routeDuration,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            safeSpots: safeSpots,
            routeType: selectedType.rawValue,
            startLatitude: startLatitude,
            startLongitude: startLongitude,
            endLatitude: endLatitude,
            endLongitude: endLongitude,
            startPlaceName: "Start Point",
            endPlaceName: "End Point"
        )

        var savedRoutes: [WalkRoute] = []

        if let data = UserDefaults.standard.data(forKey: AppStorageKeys.walkRoutes),
           let decoded = try? JSONDecoder().decode([WalkRoute].self, from: data) {
            savedRoutes = decoded
        }

        savedRoutes.insert(newRoute, at: 0)

        if let encoded = try? JSONEncoder().encode(savedRoutes) {
            UserDefaults.standard.set(encoded, forKey: AppStorageKeys.walkRoutes)
            dismiss()
        }
    }
}

enum RoutePointSelectionMode {
    case start
    case end

    var color: Color {
        switch self {
        case .start: return AppColors.primary
        case .end: return AppColors.danger
        }
    }
}

enum WalkRouteType: String, CaseIterable, Identifiable {
    case park
    case street
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .park: return "Park"
        case .street: return "Street"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .park: return "tree.fill"
        case .street: return "road.lanes"
        case .custom: return "figure.walk"
        }
    }

    var color: Color {
        switch self {
        case .park: return .green
        case .street: return AppColors.primary
        case .custom: return AppColors.secondary
        }
    }
}

#Preview {
    NavigationStack {
        CreateWalkRouteView()
    }
}
