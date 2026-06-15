//
//  PetProfileSetupView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct PetProfileSetupView: View {
    @AppStorage(AppStorageKeys.hasCreatedPetProfile)
    private var hasCreatedPetProfile = false

    @State private var petName = ""
    @State private var selectedType: PetType = .dog
    @State private var selectedGender: PetGender = .male
    @State private var ageText = ""
    @State private var breed = ""
    @State private var isFriendly = true
    @State private var isVaccinated = false
    @State private var showValidation = false
    @State private var animateCard = false

    var onComplete: (() -> Void)? = nil

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerView

                    petAvatarView

                    formCard

                    saveButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateCard = true
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Create Pet Profile")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)

                    Text("Add your pet details to unlock nearby friends, walks, and safety alerts.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.softText)
                        .lineSpacing(3)
                }

                Spacer()
            }
        }
        .opacity(animateCard ? 1 : 0)
        .offset(y: animateCard ? 0 : 16)
    }

    private var petAvatarView: some View {
        ZStack {
            Circle()
                .fill(selectedType.backgroundColor)
                .frame(width: 132, height: 132)
                .shadow(color: selectedType.color.opacity(0.22), radius: 22, x: 0, y: 14)

            Circle()
                .stroke(selectedType.color.opacity(0.22), lineWidth: 2)
                .frame(width: 112, height: 112)

            Image(systemName: selectedType.icon)
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedType.color, selectedType.color.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .scaleEffect(animateCard ? 1 : 0.82)
        .opacity(animateCard ? 1 : 0)
    }

    private var formCard: some View {
        VStack(spacing: 18) {
            inputField(
                title: "Pet Name",
                placeholder: "Enter pet name",
                text: $petName,
                icon: "pawprint.fill"
            )

            VStack(alignment: .leading, spacing: 10) {
                fieldTitle("Pet Type")

                HStack(spacing: 10) {
                    ForEach(PetType.allCases) { type in
                        selectionChip(
                            title: type.title,
                            icon: type.icon,
                            isSelected: selectedType == type,
                            color: type.color
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedType = type
                            }
                        }
                    }
                }
            }

            inputField(
                title: "Breed",
                placeholder: "Golden Retriever, Persian, etc.",
                text: $breed,
                icon: "tag.fill"
            )

            inputField(
                title: "Age",
                placeholder: "Example: 2 years",
                text: $ageText,
                icon: "calendar"
            )

            VStack(alignment: .leading, spacing: 10) {
                fieldTitle("Gender")

                HStack(spacing: 10) {
                    ForEach(PetGender.allCases) { gender in
                        selectionChip(
                            title: gender.title,
                            icon: gender.icon,
                            isSelected: selectedGender == gender,
                            color: AppColors.primary
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedGender = gender
                            }
                        }
                    }
                }
            }

            toggleRow(
                title: "Friendly with other pets",
                subtitle: "Show this for playdate matching",
                icon: "heart.fill",
                color: AppColors.secondary,
                isOn: $isFriendly
            )

            toggleRow(
                title: "Vaccinated",
                subtitle: "Helpful for safe meetups",
                icon: "cross.case.fill",
                color: AppColors.primary,
                isOn: $isVaccinated
            )

            if showValidation && !isFormValid {
                Text("Please enter pet name, breed, and age.")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 22, x: 0, y: 12)
        .offset(y: animateCard ? 0 : 22)
        .opacity(animateCard ? 1 : 0)
    }

    private var saveButton: some View {
        Button {
            savePetProfile()
        } label: {
            HStack(spacing: 10) {
                Text("Save Pet Profile")
                    .font(.system(size: 17, weight: .black, design: .rounded))

                Image(systemName: "arrow.right")
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
            .shadow(color: AppColors.primary.opacity(0.25), radius: 18, x: 0, y: 10)
        }
        .opacity(animateCard ? 1 : 0)
        .offset(y: animateCard ? 0 : 20)
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

    private func selectionChip(
        title: String,
        icon: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))

                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : AppColors.darkText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isSelected ? color : AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var backgroundDecorations: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.10))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 35)
                    .offset(x: -geo.size.width * 0.34, y: -geo.size.height * 0.32)

                Circle()
                    .fill(AppColors.secondary.opacity(0.10))
                    .frame(width: geo.size.width * 0.72)
                    .blur(radius: 35)
                    .offset(x: geo.size.width * 0.36, y: geo.size.height * 0.34)
            }
        }
    }

    private var isFormValid: Bool {
        !petName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !breed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func savePetProfile() {
        guard isFormValid else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showValidation = true
            }
            return
        }

        let profile = PetProfile(
            name: petName.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType.rawValue,
            gender: selectedGender.rawValue,
            age: ageText.trimmingCharacters(in: .whitespacesAndNewlines),
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            isFriendly: isFriendly,
            isVaccinated: isVaccinated
        )

        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: AppStorageKeys.petProfile)
            hasCreatedPetProfile = true
            onComplete?()
        }
    }
}

struct PetProfile: Codable {
    let name: String
    let type: String
    let gender: String
    let age: String
    let breed: String
    let isFriendly: Bool
    let isVaccinated: Bool
}

enum PetType: String, CaseIterable, Identifiable {
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
        case .other: return Color.purple
        }
    }

    var backgroundColor: Color {
        color.opacity(0.14)
    }
}

enum PetGender: String, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }

    var icon: String {
        switch self {
        case .male: return "mars"
        case .female: return "venus"
        }
    }
}

#Preview {
    PetProfileSetupView()
}
