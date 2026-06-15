//
//  LostPetAlertDetailView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//

import SwiftUI
import MapKit
import UIKit
import FirebaseDatabase

struct LostPetAlertDetailView: View {
    let alertId: String
    @Binding var path: NavigationPath

    @State private var alert: LostPetAlert?
    @State private var showDeleteAlert = false
    @State private var animateContent = false
    @State private var isLoading = true

    @State private var toastMessage = ""
    @State private var showToast = false

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

            if isLoading {
                ProgressView()
                    .tint(AppColors.danger)
                    .scaleEffect(1.2)
            } else if let alert {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard(alert)
                        mapCard(alert)
                        locationCard(alert)
                        descriptionCard(alert)
                        contactCard(alert)
                        actionButtons
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                }
            } else {
                notFoundView
            }

            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .navigationTitle("Alert Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadAlertFromFirebase()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .alert("Delete Alert?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAlertFromFirebase()
            }
        } message: {
            Text("This lost pet alert will be removed from Firebase and PawMate map.")
        }
    }

    private func heroCard(_ alert: LostPetAlert) -> some View {
        VStack(spacing: 16) {
            ZStack {
                if let imageBase64 = alert.imageBase64,
                   let data = Data(base64Encoded: imageBase64),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(AppColors.danger.opacity(0.22), lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(AppColors.danger.opacity(0.14))
                        .frame(width: 132, height: 132)

                    Circle()
                        .stroke(AppColors.danger.opacity(0.24), lineWidth: 2)
                        .frame(width: 108, height: 108)

                    Image(systemName: petIcon(alert.petType))
                        .font(.system(size: 58, weight: .black))
                        .foregroundColor(AppColors.danger)
                }
            }

            VStack(spacing: 6) {
                Text(alert.petName)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                    .multilineTextAlignment(.center)

                Text(alert.status)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColors.danger)
                    .clipShape(Capsule())

                Text(alert.dateText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)
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

    private func mapCard(_ alert: LostPetAlert) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lost Location Map")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Map(position: $cameraPosition) {
                Annotation(alert.petName, coordinate: alert.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: petIcon(alert.petType))
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(AppColors.danger)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                        Text("LOST")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppColors.danger)
                            .clipShape(Capsule())
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func locationCard(_ alert: LostPetAlert) -> some View {
        infoCard(
            title: "Last Seen Location",
            subtitle: alert.lastSeenLocation,
            icon: "mappin.and.ellipse",
            color: AppColors.primary
        )
    }

    private func descriptionCard(_ alert: LostPetAlert) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(AppColors.secondary)
                    .clipShape(Circle())

                Text("Description")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Spacer()
            }

            Text(alert.description)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softText)
                .lineSpacing(4)
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private func contactCard(_ alert: LostPetAlert) -> some View {
        infoCard(
            title: "Contact Number",
            subtitle: alert.contactNumber,
            icon: "phone.fill",
            color: AppColors.danger
        )
    }

    private func infoCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
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
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
        .offset(y: animateContent ? 0 : 20)
        .opacity(animateContent ? 1 : 0)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                openLostLocationInAppleMaps()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                    Text("Open Lost Location")
                }
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            Button {
                callContact()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                    Text("Call Contact")
                }
                .font(.system(size: 17, weight: .black, design: .rounded))
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
            }

            Button {
                showDeleteAlert = true
            } label: {
                Text("Delete Alert")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
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

    private var notFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70, weight: .black))
                .foregroundColor(AppColors.danger)

            Text("Alert Not Found")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("This alert may have been deleted.")
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

    private func petIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        default: return "pawprint.fill"
        }
    }

    private func loadAlertFromFirebase() {
        isLoading = true

        Database.database().reference()
            .child("lost_pet_alerts")
            .child(alertId)
            .observeSingleEvent(of: .value) { snapshot in
                DispatchQueue.main.async {
                    self.isLoading = false

                    guard let dict = snapshot.value as? [String: Any],
                          let idString = dict["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let petName = dict["petName"] as? String,
                          let petType = dict["petType"] as? String,
                          let lastSeenLocation = dict["lastSeenLocation"] as? String,
                          let description = dict["description"] as? String,
                          let contactNumber = dict["contactNumber"] as? String,
                          let dateText = dict["dateText"] as? String,
                          let status = dict["status"] as? String,
                          let latitude = dict["latitude"] as? Double,
                          let longitude = dict["longitude"] as? Double else {
                        self.alert = nil
                        return
                    }

                    let imageBase64 = dict["imageBase64"] as? String

                    let loadedAlert = LostPetAlert(
                        id: id,
                        petName: petName,
                        petType: petType,
                        lastSeenLocation: lastSeenLocation,
                        description: description,
                        contactNumber: contactNumber,
                        dateText: dateText,
                        status: status,
                        latitude: latitude,
                        longitude: longitude,
                        imageBase64: imageBase64?.isEmpty == true ? nil : imageBase64
                    )

                    self.alert = loadedAlert
                    self.moveMapToAlert(loadedAlert)
                }
            }
    }

    private func deleteAlertFromFirebase() {
        Database.database().reference()
            .child("lost_pet_alerts")
            .child(alertId)
            .removeValue { error, _ in
                DispatchQueue.main.async {
                    if let error {
                        showToastMessage(error.localizedDescription)
                    } else {
                        showToastMessage("Alert deleted successfully.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            path.removeLast()
                        }
                    }
                }
            }
    }

    private func moveMapToAlert(_ alert: LostPetAlert) {
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: alert.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
            )
        }
    }

    private func openLostLocationInAppleMaps() {
        guard let alert else { return }

        let destination = "\(alert.latitude),\(alert.longitude)"
        let urlString = "http://maps.apple.com/?daddr=\(destination)&dirflg=w"

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

    private func callContact() {
        guard let number = alert?.contactNumber.trimmingCharacters(in: .whitespacesAndNewlines),
              !number.isEmpty,
              let url = URL(string: "tel://\(number)") else {
            showToastMessage("Contact number is not valid.")
            return
        }

        UIApplication.shared.open(url) { success in
            if !success {
                showToastMessage("Unable to start call.")
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

#Preview {
    NavigationStack {
        LostPetAlertDetailView(alertId: UUID().uuidString, path: .constant(NavigationPath()))
    }
}
