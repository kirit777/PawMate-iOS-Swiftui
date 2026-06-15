//
//  PetCareRemindersView.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct PetCareRemindersView: View {
    @Binding var path: NavigationPath

    @State private var reminders: [PetReminder] = []
    @State private var animateCards = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            backgroundDecorations

            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        summaryCard

                        if reminders.isEmpty {
                            emptyState
                        } else {
                            ForEach(reminders) { reminder in
                                reminderCard(reminder)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Pet Care")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReminders()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                animateCards = true
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Pet Care Reminders")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text("Vaccination, grooming, food and vet reminders")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()

            Button {
                path.append(AppRoute.createPetReminder)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .black))
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
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var summaryCard: some View {
        HStack(spacing: 12) {
            statItem(
                title: "Total",
                value: "\(reminders.count)",
                icon: "calendar.badge.clock",
                color: AppColors.primary
            )

            statItem(
                title: "Pending",
                value: "\(reminders.filter { !$0.isCompleted }.count)",
                icon: "clock.fill",
                color: AppColors.secondary
            )
        }
        .scaleEffect(animateCards ? 1 : 0.94)
        .opacity(animateCards ? 1 : 0)
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softText)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func reminderCard(_ reminder: PetReminder) -> some View {
        Button {
            path.append(AppRoute.petReminderDetail(reminder.id.uuidString))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: reminderIcon(reminder.reminderType))
                    .font(.system(size: 21, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(reminderColor(reminder.reminderType))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(reminder.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                        .lineLimit(1)

                    Text(reminder.note)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softText)
                        .lineLimit(1)

                    Text(reminder.dateText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(reminderColor(reminder.reminderType))
                }

                Spacer()

                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "chevron.right")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(reminder.isCompleted ? AppColors.secondary : AppColors.softText.opacity(0.7))
            }
            .padding(14)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)
        }
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 76))
                .foregroundColor(AppColors.primary)

            Text("No Reminders Yet")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("Create reminders for vaccination, grooming, vet visits, food, medicine, and daily care.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                path.append(AppRoute.createPetReminder)
            } label: {
                Text("Create Reminder")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
        .offset(y: animateCards ? 0 : 20)
        .opacity(animateCards ? 1 : 0)
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

    private func reminderIcon(_ type: String) -> String {
        switch type {
        case "vaccine": return "cross.case.fill"
        case "grooming": return "scissors"
        case "food": return "fork.knife"
        case "medicine": return "pills.fill"
        default: return "calendar.badge.clock"
        }
    }

    private func reminderColor(_ type: String) -> Color {
        switch type {
        case "vaccine": return AppColors.primary
        case "grooming": return .purple
        case "food": return .orange
        case "medicine": return AppColors.danger
        default: return AppColors.secondary
        }
    }

    private func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.petCareReminders),
              let savedReminders = try? JSONDecoder().decode([PetReminder].self, from: data) else {
            reminders = []
            return
        }

        reminders = savedReminders
    }
}
