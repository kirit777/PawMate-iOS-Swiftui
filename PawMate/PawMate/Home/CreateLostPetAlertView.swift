//
//  CreateLostPetAlertView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import MapKit
import CoreLocation
import PhotosUI

struct CreateLostPetAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = PawLocationManager()

    @State private var petName = ""
    @State private var selectedType: LostPetType = .dog
    @State private var lastSeenLocation = ""
    @State private var description = ""
    @State private var contactNumber = ""
    @State private var showValidation = false
    @State private var animateContent = false

    @State private var selectedLatitude = MapConstants.defaultLatitude
    @State private var selectedLongitude = MapConstants.defaultLongitude

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: MapConstants.defaultLatitude,
                longitude: MapConstants.defaultLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
    )

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                    imagePickerCard
                    petTypeCard
                    locationPickerCard
                    formCard
                    saveButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Create Alert")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestLocation()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            guard let coordinate = newLocation?.coordinate else { return }
            selectedLatitude = coordinate.latitude
            selectedLongitude = coordinate.longitude
            moveCamera(to: coordinate)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.danger.opacity(0.14))
                    .frame(width: 116, height: 116)

                Circle()
                    .stroke(AppColors.danger.opacity(0.22), lineWidth: 2)
                    .frame(width: 94, height: 94)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(AppColors.danger)
            }

            VStack(spacing: 6) {
                Text("Lost Pet Alert")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Add pet photo and select exact lost location on map.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(animateContent ? 1 : 0.92)
        .opacity(animateContent ? 1 : 0)
    }

    private var imagePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Pet Photo")

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    if let selectedImageData,
                       let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(AppColors.danger)

                            Text("Add Pet Image")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundColor(AppColors.darkText)

                            Text("Photo helps people identify your pet faster.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.softText)
                        }
                        .frame(height: 190)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    private var petTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Pet Type")

            HStack(spacing: 10) {
                ForEach(LostPetType.allCases) { type in
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

    private var locationPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Select Lost Location")

            MapReader { proxy in
                Map(position: $cameraPosition) {
                    Annotation("Lost Location", coordinate: selectedCoordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(AppColors.danger)
                            .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
                    }

                    UserAnnotation()
                }
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        selectedLatitude = coordinate.latitude
                        selectedLongitude = coordinate.longitude
                        moveCamera(to: coordinate)
                    }
                }
            }

            Button {
                useCurrentLocation()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text("Use Current Location")
                }
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.danger)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Text("Tap on map to select where your pet was last seen.")
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
                title: "Pet Name",
                placeholder: "Enter pet name",
                text: $petName,
                icon: "pawprint.fill"
            )

            inputField(
                title: "Last Seen Location Name",
                placeholder: "Area, street, landmark",
                text: $lastSeenLocation,
                icon: "mappin.and.ellipse"
            )

            inputField(
                title: "Contact Number",
                placeholder: "Your phone number",
                text: $contactNumber,
                icon: "phone.fill",
                keyboard: .phonePad
            )

            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Description")

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.danger)
                        .frame(width: 22)
                        .padding(.top, 3)

                    TextField("Color, collar, behavior, reward info...", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                }
                .padding(14)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if showValidation && !isFormValid {
                Text("Please fill pet name, location, contact number and description.")
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
            saveAlert()
        } label: {
            HStack(spacing: 10) {
                Text("Create Lost Pet Alert")
                    .font(.system(size: 17, weight: .black, design: .rounded))

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 16, weight: .black))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    colors: [AppColors.danger, AppColors.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: AppColors.danger.opacity(0.24), radius: 16, x: 0, y: 9)
        }
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func inputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldTitle(title)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.danger)
                    .frame(width: 22)

                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
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

    private var selectedCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: selectedLatitude, longitude: selectedLongitude)
    }

    private func useCurrentLocation() {
        locationManager.requestLocation()

        if let coordinate = locationManager.userLocation?.coordinate {
            selectedLatitude = coordinate.latitude
            selectedLongitude = coordinate.longitude
            moveCamera(to: coordinate)
        }
    }

    private func moveCamera(to coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            )
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
                    .fill(AppColors.primary.opacity(0.10))
                    .frame(width: geo.size.width * 0.72)
                    .blur(radius: 35)
                    .offset(x: geo.size.width * 0.36, y: geo.size.height * 0.34)
            }
        }
    }

    private var isFormValid: Bool {
        !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastSeenLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !contactNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveAlert() {
        guard isFormValid else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showValidation = true
            }
            return
        }

        let imageBase64 = selectedImageData?.base64EncodedString()

        let newAlert = LostPetAlert(
            id: UUID(),
            petName: petName.trimmingCharacters(in: .whitespacesAndNewlines),
            petType: selectedType.rawValue,
            lastSeenLocation: lastSeenLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            contactNumber: contactNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            dateText: DateFormatter.lostAlertFormatter.string(from: Date()),
            status: "ACTIVE",
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            imageBase64: imageBase64
        )

        FirebaseLostPetService.shared.saveLostPetAlert(newAlert) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    print("Firebase save error:", error.localizedDescription)
                }
            }
        }
    }

//    private func saveAlert() {
//        guard isFormValid else {
//            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
//                showValidation = true
//            }
//            return
//        }
//
//        let imageBase64 = selectedImageData?.base64EncodedString()
//
//        let newAlert = LostPetAlert(
//            id: UUID(),
//            petName: petName.trimmingCharacters(in: .whitespacesAndNewlines),
//            petType: selectedType.rawValue,
//            lastSeenLocation: lastSeenLocation.trimmingCharacters(in: .whitespacesAndNewlines),
//            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
//            contactNumber: contactNumber.trimmingCharacters(in: .whitespacesAndNewlines),
//            dateText: DateFormatter.lostAlertFormatter.string(from: Date()),
//            status: "ACTIVE",
//            latitude: selectedLatitude,
//            longitude: selectedLongitude,
//            imageBase64: imageBase64
//        )
//
//        var savedAlerts: [LostPetAlert] = []
//
//        if let data = UserDefaults.standard.data(forKey: AppStorageKeys.lostPetAlerts),
//           let decoded = try? JSONDecoder().decode([LostPetAlert].self, from: data) {
//            savedAlerts = decoded
//        }
//
//        savedAlerts.insert(newAlert, at: 0)
//
//        if let encoded = try? JSONEncoder().encode(savedAlerts) {
//            UserDefaults.standard.set(encoded, forKey: AppStorageKeys.lostPetAlerts)
//            dismiss()
//        }
//    }
}

enum LostPetType: String, CaseIterable, Identifiable {
    case dog
    case cat
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .other: return "pawprint.fill"
        }
    }

    var color: Color {
        switch self {
        case .dog: return AppColors.primary
        case .cat: return AppColors.secondary
        case .other: return .purple
        }
    }
}

extension DateFormatter {
    static let lostAlertFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        CreateLostPetAlertView()
    }
}
