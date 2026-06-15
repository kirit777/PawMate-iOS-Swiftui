import SwiftUI
import Foundation
import MapKit

enum AppConstants {
    static let appName = "PawMate"
    static let appTagline = "Walk. Connect. Protect."
    static let splashDuration: Double = 2.4
}



enum AppStorageKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let hasCreatedPetProfile = "hasCreatedPetProfile"
    static let petProfile = "petProfile"
    static let walkRoutes = "walkRoutes"
    static let lostPetAlerts = "lostPetAlerts"
    static let petCareReminders = "petCareReminders"
    static let myPets = "myPets"
}



struct PetPlace: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: PetMapCategory
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distanceText: String

    static func == (lhs: PetPlace, rhs: PetPlace) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum AppRoute: Hashable {
    case nearbyPlaces
    case placeDetail(PetPlace)
    case routeDirection(PetPlace)

    case myPets

    case safeWalkRoutes
    case createWalkRoute
    case walkRouteDetail(String)

    case lostPetAlerts
    case createLostPetAlert
    case lostPetAlertDetail(String)

    case petCareReminders
    case createPetReminder
    case petReminderDetail(String)

    case settings
}

enum PermissionMessages {
    static let locationUsage = "PawMate needs your location to show nearby vets, pet shops, parks, and lost pet alerts around you."
}

enum MapConstants {
    static let defaultLatitude = 22.3039
    static let defaultLongitude = 70.8022
    static let defaultSpan = 0.045
}

struct PetReminder: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let note: String
    let dateText: String
    let reminderType: String
    let isCompleted: Bool
}

struct LostPetAlert: Identifiable, Codable, Hashable {
    let id: UUID
    let petName: String
    let petType: String
    let lastSeenLocation: String
    let description: String
    let contactNumber: String
    let dateText: String
    let status: String
    
    let latitude: Double
    let longitude: Double
    let imageBase64: String?
}

enum AppColors {
    static let primary = Color(hex: "#FF8A3D")
    static let secondary = Color(hex: "#4ECDC4")
    static let darkText = Color(hex: "#1F2937")
    static let softText = Color(hex: "#6B7280")
    static let background = Color(hex: "#FFF8F1")
    static let card = Color.white
    static let lightOrange = Color(hex: "#FFE7D4")
    static let lightMint = Color(hex: "#DDF8F5")
    static let danger = Color(hex: "#EF4444")
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 255
            g = 255
            b = 255
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}


import MapKit

extension LostPetAlert {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var mapIcon: String {
        switch petType {
        case "dog": return "dog.fill"
        case "cat": return "cat.fill"
        default: return "pawprint.fill"
        }
    }
}
