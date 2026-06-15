//
//  PetReminderDetailView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct PetReminderDetailView: View {
    let reminderId: String
    @Binding var path: NavigationPath

    @State private var reminder: PetReminder?
    @State private var showDeleteAlert = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            if let reminder {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroCard(reminder)
                        noteCard(reminder)
                        statusCard(reminder)
                        actionButtons(reminder)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                }
            } else {
                notFoundView
            }
        }
        .navigationTitle("Reminder Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReminder()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .alert("Delete Reminder?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteReminder()
            }
        } message: {
            Text("This reminder will be removed from PawMate.")
        }
    }

    private func heroCard(_ reminder: PetReminder) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(reminderColor(reminder.reminderType).opacity(0.14))
                    .frame(width: 132, height: 132)

                Circle()
                    .stroke(reminderColor(reminder.reminderType).opacity(0.24), lineWidth: 2)
                    .frame(width: 108, height: 108)

                Image(systemName: reminderIcon(reminder.reminderType))
                    .font(.system(size: 58, weight: .black))
                    .foregroundColor(reminderColor(reminder.reminderType))
            }

            VStack(spacing: 6) {
                Text(reminder.title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                    .multilineTextAlignment(.center)

                Text(reminder.dateText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)

                Text(reminder.reminderType.capitalized)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(reminderColor(reminder.reminderType))
                    .clipShape(Capsule())
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

    private func noteCard(_ reminder: PetReminder) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(AppColors.primary)
                    .clipShape(Circle())

                Text("Reminder Note")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Spacer()
            }

            Text(reminder.note)
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

    private func statusCard(_ reminder: PetReminder) -> some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(reminder.isCompleted ? AppColors.secondary : AppColors.danger)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.isCompleted ? "Completed" : "Pending")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(reminder.isCompleted ? "This care task is done." : "This care task is still pending.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
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

    private func actionButtons(_ reminder: PetReminder) -> some View {
        VStack(spacing: 12) {
            Button {
                toggleCompleted()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: reminder.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                    Text(reminder.isCompleted ? "Mark as Pending" : "Mark as Completed")
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
            }

            Button {
                showDeleteAlert = true
            } label: {
                Text("Delete Reminder")
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

    private var notFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70, weight: .black))
                .foregroundColor(AppColors.danger)

            Text("Reminder Not Found")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("This reminder may have been deleted.")
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

    private func loadReminder() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.petCareReminders),
              let reminders = try? JSONDecoder().decode([PetReminder].self, from: data) else {
            reminder = nil
            return
        }

        reminder = reminders.first { $0.id.uuidString == reminderId }
    }

    private func toggleCompleted() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.petCareReminders),
              var reminders = try? JSONDecoder().decode([PetReminder].self, from: data),
              let index = reminders.firstIndex(where: { $0.id.uuidString == reminderId }) else {
            return
        }

        let old = reminders[index]

        reminders[index] = PetReminder(
            id: old.id,
            title: old.title,
            note: old.note,
            dateText: old.dateText,
            reminderType: old.reminderType,
            isCompleted: !old.isCompleted
        )

        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: AppStorageKeys.petCareReminders)
            reminder = reminders[index]
        }
    }

    private func deleteReminder() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.petCareReminders),
              var reminders = try? JSONDecoder().decode([PetReminder].self, from: data) else {
            return
        }

        reminders.removeAll { $0.id.uuidString == reminderId }

        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: AppStorageKeys.petCareReminders)
        }

        path.removeLast()
    }

    private func reminderIcon(_ type: String) -> String {
        switch type {
        case "vaccine": return "cross.case.fill"
        case "grooming": return "scissors"
        case "food": return "fork.knife"
        case "medicine": return "pills.fill"
        case "vet": return "stethoscope"
        default: return "calendar.badge.clock"
        }
    }

    private func reminderColor(_ type: String) -> Color {
        switch type {
        case "vaccine": return AppColors.primary
        case "grooming": return .purple
        case "food": return .orange
        case "medicine": return AppColors.danger
        case "vet": return AppColors.secondary
        default: return AppColors.primary
        }
    }
}

#Preview {
    NavigationStack {
        PetReminderDetailView(reminderId: UUID().uuidString, path: .constant(NavigationPath()))
    }
}