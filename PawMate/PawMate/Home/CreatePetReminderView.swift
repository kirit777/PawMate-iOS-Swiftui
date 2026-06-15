//
//  CreatePetReminderView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct CreatePetReminderView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var note = ""
    @State private var selectedType: PetReminderType = .vaccine
    @State private var selectedDate = Date()
    @State private var showValidation = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                    reminderTypeCard
                    formCard
                    saveButton
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Create Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
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
                Text("Create Care Reminder")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Set reminders for vaccine, grooming, food, medicine and vet care.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(animateContent ? 1 : 0.92)
        .opacity(animateContent ? 1 : 0)
    }

    private var reminderTypeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Reminder Type")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(PetReminderType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedType = type
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.system(size: 18, weight: .black))

                            Text(type.title)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedType == type ? .white : AppColors.darkText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(selectedType == type ? type.color : AppColors.background)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private var formCard: some View {
        VStack(spacing: 18) {
            inputField(
                title: "Reminder Title",
                placeholder: "Rabies vaccine, grooming, food refill...",
                text: $title,
                icon: "calendar.badge.clock"
            )

            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Reminder Date")

                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Note")

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(selectedType.color)
                        .frame(width: 22)
                        .padding(.top, 3)

                    TextField("Add reminder note...", text: $note, axis: .vertical)
                        .lineLimit(4...6)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                }
                .padding(14)
                .background(AppColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if showValidation && !isFormValid {
                Text("Please fill reminder title and note.")
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
            saveReminder()
        } label: {
            HStack(spacing: 10) {
                Text("Save Reminder")
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
                    .foregroundColor(selectedType.color)
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
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveReminder() {
        guard isFormValid else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showValidation = true
            }
            return
        }

        let newReminder = PetReminder(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            dateText: DateFormatter.petReminderFormatter.string(from: selectedDate),
            reminderType: selectedType.rawValue,
            isCompleted: false
        )

        var savedReminders: [PetReminder] = []

        if let data = UserDefaults.standard.data(forKey: AppStorageKeys.petCareReminders),
           let decoded = try? JSONDecoder().decode([PetReminder].self, from: data) {
            savedReminders = decoded
        }

        savedReminders.insert(newReminder, at: 0)

        if let encoded = try? JSONEncoder().encode(savedReminders) {
            UserDefaults.standard.set(encoded, forKey: AppStorageKeys.petCareReminders)
            dismiss()
        }
    }
}

enum PetReminderType: String, CaseIterable, Identifiable {
    case vaccine
    case grooming
    case food
    case medicine
    case vet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vaccine: return "Vaccine"
        case .grooming: return "Grooming"
        case .food: return "Food"
        case .medicine: return "Medicine"
        case .vet: return "Vet"
        }
    }

    var icon: String {
        switch self {
        case .vaccine: return "cross.case.fill"
        case .grooming: return "scissors"
        case .food: return "fork.knife"
        case .medicine: return "pills.fill"
        case .vet: return "stethoscope"
        }
    }

    var color: Color {
        switch self {
        case .vaccine: return AppColors.primary
        case .grooming: return .purple
        case .food: return .orange
        case .medicine: return AppColors.danger
        case .vet: return AppColors.secondary
        }
    }
}

extension DateFormatter {
    static let petReminderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        CreatePetReminderView()
    }
}