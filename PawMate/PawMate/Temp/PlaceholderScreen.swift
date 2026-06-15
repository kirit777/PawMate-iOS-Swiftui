//
//  PlaceholderScreen.swift
//  PawMate
//
//  Created by Kirit on 27/05/26.
//


import SwiftUI

struct PlaceholderScreen: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 70, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(title)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)

                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}