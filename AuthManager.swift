import FirebaseAuth

class AuthManager {
    static let shared = AuthManager()
    private init() {}

    func signUp(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let uid = result?.user.uid {
                completion(.success(uid))
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let uid = result?.user.uid {
                completion(.success(uid))
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    func getCurrentUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
}
