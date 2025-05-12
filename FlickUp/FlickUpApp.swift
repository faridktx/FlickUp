import Firebase
import SwiftUI
import MapKit
import Foundation

@main
struct FlickUpApp: App {
    @State private var isLoggedIn: Bool = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                AppMainView()
            } else {
                AuthGate()
            }
        }
    }
}

// Note: Add the following property to the Party struct in your model:
// let coverPhotoURL: String?
// Remember to update HomeView and PartyDetailView to utilize this new property.
// Please open HomeView.swift for further modifications related to displaying cover photos.

struct MapView: View {
    var body: some View {
        Text("Map View (Interactive map with event markers coming soon)")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View (User bios, uploads, and events)")
    }
}
