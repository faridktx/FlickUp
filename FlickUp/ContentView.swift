import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var status = ""

    var body: some View {
        VStack(spacing: 25) {
            Text("FlickUp Login")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            VStack(spacing: 15) {
                Text("Login Credentials")
                    .font(.headline)
                    .padding(.bottom, 5)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .padding(.horizontal)
            }

            VStack(spacing: 10) {
                Text("Actions")
                    .font(.headline)
                    .padding(.bottom, 5)

                Button("Sign Up") {
                    AuthManager.shared.signUp(email: email, password: password) { result in
                        switch result {
                        case .success(let uid):
                            let db = Firestore.firestore()
                            db.collection("users").document(uid).setData([
                                "username": email.components(separatedBy: "@").first ?? "newuser",
                                "email": email,
                                "profile_pic_url": "",
                                "joined_at": Timestamp(),
                                "parties_joined": []
                            ]) { error in
                                if let error = error {
                                    status = "❌ Firestore error: \(error.localizedDescription)"
                                } else {
                                    status = "✅ Signed up & user profile created! UID: \(uid)"
                                    DispatchQueue.main.async {
                                        isLoggedIn = true
                                    }
                                }
                            }

                        case .failure(let error):
                            status = "❌ Auth error: \(error.localizedDescription)"
                        }
                    }
                }

                Button("Sign In") {
                    AuthManager.shared.signIn(email: email, password: password) { result in
                        switch result {
                        case .success(let uid):
                            status = "✅ Signed in! UID: \(uid)"
                            DispatchQueue.main.async {
                                isLoggedIn = true
                            }
                        case .failure(let error):
                            status = "❌ \(error.localizedDescription)"
                        }
                    }
                }
            }

            Text(status)
                .foregroundColor(status.contains("✅") ? .green : .red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding()
        }
        .padding()
    }
}
