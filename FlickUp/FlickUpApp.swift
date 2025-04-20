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

struct MapView: View {
    var body: some View {
        Text("Map View Coming Soon")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View Coming Soon")
    }
}
