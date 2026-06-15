//
//  MyPetsView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct MyPetsView: View {
    @State private var savedPet: PetProfile?
    @State private var animateCards = false
    @State private var showPetSetup = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if let savedPet {
                            petCard(savedPet)
                            quickInfoSection(savedPet)
                        } else {
                            emptyStateView
                        }

                        actionButtons
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            loadPetProfile()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateCards = true
            }
        }
        .sheet(isPresented: $showPetSetup, onDismiss: loadPetProfile) {
            PetProfileSetupView {
                showPetSetup = false
                loadPetProfile()
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("My Pets")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Manage your pet profile and safety details")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()

            Image(systemName: "pawprint.fill")
                .font(.system(size: 22, weight: .black))
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
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func petCard(_ pet: PetProfile) -> some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(petAccentColor.opacity(0.14))
                    .frame(width: 130, height: 130)

                Circle()
                    .stroke(petAccentColor.opacity(0.22), lineWidth: 2)
                    .frame(width: 108, height: 108)

                Image(systemName: petIcon)
                    .font(.system(size: 58, weight: .black))
                    .foregroundColor(petAccentColor)
            }

            VStack(spacing: 6) {
                Text(pet.name)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("\(pet.breed) • \(pet.age)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            HStack(spacing: 10) {
                statusChip(
                    title: pet.gender.capitalized,
                    icon: pet.gender == "male" ? "mars" : "venus",
                    color: AppColors.primary
                )

                statusChip(
                    title: pet.type.capitalized,
                    icon: petIcon,
                    color: petAccentColor
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 22, x: 0, y: 12)
        .scaleEffect(animateCards ? 1 : 0.92)
        .opacity(animateCards ? 1 : 0)
    }

    private func quickInfoSection(_ pet: PetProfile) -> some View {
        VStack(spacing: 12) {
            infoRow(
                title: "Friendly with other pets",
                subtitle: pet.isFriendly ? "Available for playdates" : "Not marked for playdates",
                icon: "heart.fill",
                color: AppColors.secondary,
                isActive: pet.isFriendly
            )

            infoRow(
                title: "Vaccination Status",
                subtitle: pet.isVaccinated ? "Marked as vaccinated" : "Not marked as vaccinated",
                icon: "cross.case.fill",
                color: AppColors.primary,
                isActive: pet.isVaccinated
            )
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
    }

    private func infoRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isActive: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(isActive ? color : AppColors.softText.opacity(0.45))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()

            Image(systemName: isActive ? "checkmark.circle.fill" : "minus.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(isActive ? color : AppColors.softText.opacity(0.5))
        }
        .padding(14)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 76))
                .foregroundColor(AppColors.primary)

            Text("No Pet Profile Found")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("Create your pet profile to use nearby friends, lost pet alerts, and safe walking features.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 22, x: 0, y: 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showPetSetup = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: savedPet == nil ? "plus" : "pencil")
                        .font(.system(size: 16, weight: .black))

                    Text(savedPet == nil ? "Create Pet Profile" : "Edit Pet Profile")
                        .font(.system(size: 17, weight: .black, design: .rounded))
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
                .shadow(color: AppColors.primary.opacity(0.25), radius: 18, x: 0, y: 10)
            }

            if savedPet != nil {
                Button {
                    deletePetProfile()
                } label: {
                    Text("Delete Pet Profile")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
    }

    private func statusChip(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .black))

            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
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

    private var petIcon: String {
        switch savedPet?.type {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        default: return "pawprint.fill"
        }
    }

    private var petAccentColor: Color {
        switch savedPet?.type {
        case "dog": return AppColors.primary
        case "cat": return AppColors.secondary
        default: return Color.purple
        }
    }

    private func loadPetProfile() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.petProfile),
              let profile = try? JSONDecoder().decode(PetProfile.self, from: data) else {
            savedPet = nil
            return
        }

        savedPet = profile
    }

    private func deletePetProfile() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            UserDefaults.standard.removeObject(forKey: AppStorageKeys.petProfile)
            UserDefaults.standard.set(false, forKey: AppStorageKeys.hasCreatedPetProfile)
            savedPet = nil
        }
    }
}

#Preview {
    MyPetsView()
}
