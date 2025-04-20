import SwiftUI
import FirebaseAuth

struct AuthGate: View {
    @State private var isLoggedIn: Bool = false

    var body: some View {
        ZStack {
            if isLoggedIn {
                AppMainView()
            } else {
                ContentView(isLoggedIn: $isLoggedIn)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            isLoggedIn = Auth.auth().currentUser != nil
        }
    }
}
