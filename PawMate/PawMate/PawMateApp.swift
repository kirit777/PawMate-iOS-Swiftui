import SwiftUI
import Firebase
import FirebaseCore

@main
struct PawMateApp: App {
    
    @AppStorage(AppStorageKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false
    
    @AppStorage(AppStorageKeys.hasCreatedPetProfile)
    private var hasCreatedPetProfile = false
    
    @State private var showSplash = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                } else {
                    if !hasCompletedOnboarding {
                        OnboardingView {
                            hasCompletedOnboarding = true
                        }
                    } else if !hasCreatedPetProfile {
                        PetProfileSetupView {
                            hasCreatedPetProfile = true
                        }
                    } else {
                        HomeMapView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showSplash)
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.35), value: hasCreatedPetProfile)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.splashDuration) {
                    showSplash = false
                }
            }
        }
    }
}
