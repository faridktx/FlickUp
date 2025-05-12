import SwiftUI

extension Color {
    static let gold = Color(red: 212/255, green: 175/255, blue: 55/255)
}
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage
import CoreImage.CIFilterBuiltins
import UserNotifications
import MapKit

struct Party: Identifiable {
    let id: String
    let name: String
    let location: String
    let code: String
    let createdAt: Date
    let imageURL: String?
    let memberCount: Int
    let hostID: String
}

struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct PartyMapAnnotation: Identifiable {
    let id = UUID()
    let party: Party
    let coordinate: CLLocationCoordinate2D
}

struct AppMainView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        if isLoggedIn {
            NavigationView {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    TabView {
                        FeedView()
                            .tabItem {
                                Image(systemName: "rectangle.stack.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                        SearchView()
                            .tabItem {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                        MapView()
                            .tabItem {
                                Image(systemName: "map.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                        HomeView()
                            .tabItem {
                                Image(systemName: "calendar.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                        NotificationsView()
                            .tabItem {
                                Image(systemName: "bell.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                        UserProfileView()
                            .tabItem {
                                Image(systemName: "person.crop.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white)
                            }
                    }
                    .accentColor(.white)
                    .background(Color.black.edgesIgnoringSafeArea(.bottom))
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        } else {
            AuthGate()
        }
    }
}

struct NotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue.opacity(0.7))
            Text("No notifications yet.")
                .font(.title2)
                .foregroundColor(.gray)
            Text("We'll let you know when something important happens.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle("Notifications")
    }
}

struct FeedItem: Identifiable {
    let id: String
    let imageURL: String
    let uploaderID: String
    let isVaulted: Bool
    let partyID: String
    var likes: [String]
}

struct FeedView: View {
    @State private var feedItems: [FeedItem] = []
    @State private var selectedItem: FeedItem? = nil
    @State private var showCommentSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                if feedItems.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "photo.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray.opacity(0.4))
                        Text("Your feed is empty")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.gray)
                        Text("Join a party to see photos shared by others.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LazyVStack(spacing: 24) {
                        ForEach(feedItems.indices, id: \.self) { index in
                            let item = feedItems[index]
                            VStack(alignment: .leading, spacing: 10) {
                                // Image with overlay
                                ZStack(alignment: .bottomTrailing) {
                                    AsyncImage(url: URL(string: item.imageURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity, maxHeight: 400)
                                            .clipped()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 400)
                                            .overlay(ProgressView())
                                    }

                                    if item.isVaulted {
                                        Text("Vaulted")
                                            .font(.caption)
                                            .padding(6)
                                            .background(Color.red.opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                            .padding(8)
                                    }
                                }

                                // Post details
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Uploaded by \(item.uploaderID)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    // ACTION BUTTONS HSTACK
                                    HStack(spacing: 18) {
                                        Button(action: {
                                            toggleLike(for: index)
                                        }) {
                                            Image(systemName: item.likes.contains(currentUserID()) ? "heart.fill" : "heart")
                                                .foregroundColor(item.likes.contains(currentUserID()) ? .gold : .white)
                                        }

                                        Text("\(item.likes.count)")
                                            .font(.footnote)
                                            .foregroundColor(.gray)

                                        Button(action: {
                                            DispatchQueue.main.async {
                                                selectedItem = item
                                                showCommentSheet = true
                                            }
                                        }) {
                                            Image(systemName: "text.bubble")
                                                .foregroundColor(.white)
                                        }

                                        Spacer()

                                        Button(action: {}) {
                                            Image(systemName: "archivebox")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .font(.system(size: 18))
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 8)
                            }
                            .background(
                                Color(.systemGray6).opacity(0.15)
                            )
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .background(Color.black)
            .navigationTitle("FlickUp")
            .onAppear {
                Task {
                    await fetchAllMedia()
                }
            }
        }
        .background(Color.black)
        .sheet(item: $selectedItem) { selected in
            NavigationView {
                CommentView(partyID: selected.partyID, mediaID: selected.id)
            }
        }
    }

    func currentUserID() -> String {
        Auth.auth().currentUser?.uid ?? "unknown"
    }

    func toggleLike(for index: Int) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        var item = feedItems[index]
        let docRef = Firestore.firestore()
            .collection("parties")
            .document(item.partyID)
            .collection("media")
            .document(item.id)

        if item.likes.contains(userID) {
            item.likes.removeAll { $0 == userID }
        } else {
            item.likes.append(userID)
        }

        feedItems[index] = item
        docRef.updateData(["likes": item.likes])
    }

    func fetchAllMedia() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No logged-in user.")
            return
        }

        let db = Firestore.firestore()
        do {
            // Only get parties the user has joined
            let partiesSnapshot = try await db.collection("parties")
                .whereField("members", arrayContains: uid)
                .getDocuments()

            var allMedia: [FeedItem] = []

            for partyDoc in partiesSnapshot.documents {
                let partyID = partyDoc.documentID
                let mediaSnapshot = try await db.collection("parties")
                    .document(partyID)
                    .collection("media")
                    .getDocuments()

                for doc in mediaSnapshot.documents {
                    let data = doc.data()
                    guard let url = data["media_url"] as? String,
                          let uploader = data["uploader_id"] as? String,
                          let isVaulted = data["is_vaulted"] as? Bool else { continue }

                    let likes = data["likes"] as? [String] ?? []
                    allMedia.append(FeedItem(id: doc.documentID, imageURL: url, uploaderID: uploader, isVaulted: isVaulted, partyID: partyID, likes: likes))
                }
            }

            self.feedItems = allMedia.sorted { $0.id > $1.id }
        } catch {
            print("❌ Error loading filtered feed: \(error.localizedDescription)")
        }
    }
}

struct HomeView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapAnnotations: [PartyMapAnnotation] = []
    @State private var parties: [Party] = []
    @State private var hostedParties: [Party] = []
    @State private var statusMessage: String = ""
    @State private var showCreateParty = false
    @State private var partyName = ""
    @State private var partyLocation = ""
    @State private var partyImageURL = ""
    @State private var showJoinParty = false
    @State private var joinCode = ""
    @State private var joinMethod = "Code"
    @State private var showQRScanner = false
    @State private var showCommentSheet = false
    @State private var selectedItem: FeedItem? = nil
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    let joinMethods = ["Code", "QR"]
    @State private var selectedCoverImage: UIImage? = nil
    @State private var selectedCoverItem: PhotosPickerItem? = nil
    @State private var selectedPartyToEdit: Party? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                if parties.isEmpty {
                    Text("You haven't joined any parties yet.")
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(parties) { party in
                                NavigationLink(destination:
                                    PartyDetailView(party: party)
                                        .navigationBarBackButtonHidden(false)
                                        .toolbar {
                                            ToolbarItem(placement: .navigationBarLeading) {
                                                Button(action: {
                                                    // Provide a way to go back if needed
                                                    // This is a placeholder; SwiftUI's NavigationLink provides back by default
                                                }) {
                                                    Image(systemName: "chevron.backward")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                ) {
                                    ZStack(alignment: .bottomLeading) {
                                        AsyncImage(url: URL(string: party.imageURL ?? "")) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 220)
                                                .clipped()
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                                .frame(height: 220)
                                        }

                                        // Bottom gradient layer for title and controls
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.black.opacity(0.7), .clear]),
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                        .frame(height: 100)
                                        .frame(maxHeight: .infinity, alignment: .bottom)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(party.name)
                                                .font(.title2)
                                                .bold()
                                                .foregroundColor(.white)

                                            HStack(spacing: 6) {
                                                Image(systemName: "mappin.and.ellipse")
                                                    .foregroundColor(.white)
                                                    .imageScale(.small)
                                                Text(party.location)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(6)
                                            .background(Color.black.opacity(0.4))
                                            .cornerRadius(8)
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 40) // leave space for bottom controls

                                        // Bottom right controls
                                        HStack {
                                            Spacer()
                                            HStack(spacing: 8) {
                                                Button {
                                                    // Optional: Add join logic
                                                } label: {
                                                    Label("Join", systemImage: "checkmark.circle.fill")
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(Color.gold.opacity(0.85))
                                                        .foregroundColor(.black)
                                                        .clipShape(Capsule())
                                                }
                                                Label("\(party.memberCount)", systemImage: "person.3.fill")
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(Color.gold.opacity(0.85))
                                                    .foregroundColor(.black)
                                                    .clipShape(Capsule())
                                            }
                                            .font(.footnote)
                                        }
                                        .padding([.horizontal, .bottom], 12)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    }
                                    .background(Color.black)
                                    .cornerRadius(18)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button(action: { showCreateParty = true }) {
                        Text("+ Start Party")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .sheet(isPresented: $showCreateParty) {
                        VStack(spacing: 20) {
                            Text("Create a New Party")
                                .font(.title2)
                                .bold()

                            TextField("Party Name", text: $partyName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            TextField("Location (optional)", text: $partyLocation)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            PhotosPicker(selection: $selectedCoverItem, matching: .images) {
                                Text("📸 Select Cover Photo")
                                    .padding()
                                    .background(Color.yellow.opacity(0.1))
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                            .onChange(of: selectedCoverItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        selectedCoverImage = uiImage
                                    }
                                }
                            }

                            if let image = selectedCoverImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }

                            Button(action: { createParty() }) {
                                Text("Create")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gold)
                            .foregroundColor(.black)
                            .cornerRadius(12)

                            Button("Cancel", role: .cancel) {
                                showCreateParty = false
                            }
                        }
                        .padding()
                    }
                    .sheet(item: $selectedPartyToEdit) { party in
                        EditPartyView(party: party) {
                            fetchUserParties()
                        }
                    }

                    Button(action: { showJoinParty = true }) {
                        Text("Join Party")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .sheet(isPresented: $showJoinParty) {
                        VStack(spacing: 20) {
                            Text("Join a Party")
                                .font(.title2)
                                .bold()

                            Picker("Method", selection: $joinMethod) {
                                ForEach(joinMethods, id: \.self) { method in
                                    Text(method)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)

                            if joinMethod == "Code" {
                                TextField("Enter Party Code", text: $joinCode)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.allCharacters)
                                    .padding(.horizontal)

                                Button(action: { joinParty(withCode: joinCode.uppercased()) }) {
                                    Text("Join with Code")
                                        .fontWeight(.bold)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gold)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            } else if joinMethod == "QR" {
                                Button(action: { showQRScanner = true }) {
                                    Text("📷 Scan QR Code")
                                        .fontWeight(.bold)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gold)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .sheet(isPresented: $showQRScanner) {
                                    QRScannerView { code in
                                        showQRScanner = false
                                        joinParty(withCode: code.uppercased())
                                    }
                                }
                            }

                            Button("Cancel", role: .cancel) {
                                showJoinParty = false
                            }
                        }
                        .padding()
                    }

                    Button(action: { fetchUserParties() }) {
                        Text("Refresh Parties")
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gold)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }

                // Sign Out button removed

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .background(Color.black)
            .onAppear {
                fetchUserParties()
            }
            .fullScreenCover(isPresented: $showCommentSheet) {
                if let selected = selectedItem {
                    NavigationView {
                        CommentView(partyID: selected.partyID, mediaID: selected.id)
                    }
                }
            }
        }
    }

    private func fetchUserParties() {
        guard let uid = Auth.auth().currentUser?.uid else {
            statusMessage = "User not logged in."
            return
        }

        let db = Firestore.firestore()
        db.collection("parties").whereField("members", arrayContains: uid).getDocuments { snapshot, error in
            if let error = error {
                statusMessage = "Error fetching parties: \(error.localizedDescription)"
            } else if let docs = snapshot?.documents {
                parties = docs.compactMap { doc in
                    let data = doc.data()
                    let memberCount = (data["members"] as? [String])?.count ?? 1
                    let hostID = data["host_id"] as? String ?? ""
                    guard
                        let name = data["party_name"] as? String,
                        let code = data["party_code"] as? String,
                        let timestamp = data["created_at"] as? Timestamp
                    else {
                        return Party(
                            id: doc.documentID,
                            name: "Unnamed Party",
                            location: "Unknown",
                            code: "UNKNOWN",
                            createdAt: Date(),
                            imageURL: nil,
                            memberCount: memberCount,
                            hostID: hostID
                        )
                    }

                    let location = data["location"] as? String ?? "Unknown"
                    let imageURL = data["image_url"] as? String
                    return Party(
                        id: doc.documentID,
                        name: name,
                        location: location,
                        code: code,
                        createdAt: timestamp.dateValue(),
                        imageURL: imageURL,
                        memberCount: memberCount,
                        hostID: hostID
                    )
                }
                self.mapAnnotations = parties.compactMap { party in
                    // Here you should actually extract stored GeoPoint values from Firestore if you have coordinates saved,
                    // for now we simulate with a dummy location to avoid crashing
                    if party.location.lowercased() == "unknown" {
                        return nil
                    }

                    // Example coordinates – in practice you'd parse actual stored latitude and longitude
                    let dummyCoordinates = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                    return PartyMapAnnotation(party: party, coordinate: dummyCoordinates)
                }
                statusMessage = ""
            }
        }
    }

    private func createParty() {
        guard let uid = Auth.auth().currentUser?.uid else {
            statusMessage = "User not logged in."
            return
        }

        let db = Firestore.firestore()
        let partyID = UUID().uuidString
        let partyCode = String(partyID.prefix(6)).uppercased()

        db.collection("parties").document(partyID).setData([
            "party_name": partyName,
            "host_id": uid,
            "created_at": Timestamp(),
            "event_date": Timestamp(date: Date()),
            "party_code": partyCode,
            "is_active": true,
            "location": partyLocation,
            "members": [uid],
            "image_url": partyImageURL,
            "member_count": 1
        ]) { error in
            if let error = error {
                statusMessage = "❌ Failed to create party: \(error.localizedDescription)"
            } else {
                statusMessage = "✅ Party created!"
                partyName = ""
                partyLocation = ""
                partyImageURL = ""
                showCreateParty = false
                fetchUserParties()
            }
        }
    }
    
    private func joinParty(withCode code: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            statusMessage = "User not logged in."
            return
        }
        
        let db = Firestore.firestore()
        db.collection("parties").whereField("party_code", isEqualTo: code).getDocuments { snapshot, error in
            if let error = error {
                statusMessage = "❌ Error finding party: \(error.localizedDescription)"
            } else if let doc = snapshot?.documents.first {
                let partyID = doc.documentID
                db.collection("parties").document(partyID).updateData([
                    "members": FieldValue.arrayUnion([uid])
                ]) { err in
                    if let err = err {
                        statusMessage = "❌ Failed to join: \(err.localizedDescription)"
                    } else {
                        // Increment the member count field
                        db.collection("parties").document(partyID).updateData([
                            "member_count": FieldValue.increment(Int64(1))
                        ])
                        statusMessage = "✅ Successfully joined!"
                        showJoinParty = false
                        fetchUserParties()
                    }
                }
            } else {
                statusMessage = "❌ Invalid party code."
            }
        }
    }

    private func fetchHostedParties() {
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            db.collection("parties")
                .whereField("host_id", isEqualTo: uid)
                .getDocuments { snapshot, error in
                    if let docs = snapshot?.documents {
                        hostedParties = docs.compactMap { doc in
                            let data = doc.data()
                            let memberCount = (data["members"] as? [String])?.count ?? 1
                            let hostID = data["host_id"] as? String ?? ""
                            guard
                                let name = data["party_name"] as? String,
                                let code = data["party_code"] as? String,
                                let timestamp = data["created_at"] as? Timestamp
                            else {
                                return Party(
                                    id: doc.documentID,
                                    name: "Unnamed Party",
                                    location: "Unknown",
                                    code: "UNKNOWN",
                                    createdAt: Date(),
                                    imageURL: nil,
                                    memberCount: memberCount,
                                    hostID: hostID
                                )
                            }
                            let location = data["location"] as? String ?? "Unknown"
                            let imageURL = data["image_url"] as? String
                            return Party(
                                id: doc.documentID,
                                name: name,
                                location: location,
                                code: code,
                                createdAt: timestamp.dateValue(),
                                imageURL: imageURL,
                                memberCount: memberCount,
                                hostID: hostID
                            )
                        }
                    }
                }
        } else {
            print("❌ No user ID found.")
        }
    }

    private func deleteParty(_ party: Party) {
        let db = Firestore.firestore()
        db.collection("parties").document(party.id).delete { error in
            if let error = error {
                print("❌ Failed to delete party: \(error.localizedDescription)")
            } else {
                hostedParties.removeAll { $0.id == party.id }
            }
        }
    }
}

struct PartyDetailView: View {
    let party: Party
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var uploadStatus: String = ""
    @State private var mediaItems: [(url: String, type: String, isVaulted: Bool)] = []
    @State private var showVaultedOnly = false
    @State private var showQRSheet = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Cover Image with overlay
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: party.imageURL ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .clipped()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                                .frame(height: 220)
                        }

                        // Top overlay: party name & location
                        VStack(alignment: .leading, spacing: 4) {
                            Text(party.name)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)

                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.white)
                                    .imageScale(.small)
                                Text(party.location)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 40)
                    }
                    .background(Color.black)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top)

                    // Party Info
                    VStack(spacing: 6) {
                        Text("Party Code: \(party.code)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Created: \(party.createdAt.formatted(.dateTime.month().day().year().hour().minute()))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Actions
                    HStack(spacing: 12) {
                        Button("Show QR Code") {
                            showQRSheet = true
                        }
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)

                        Button("Take Photo") {
                            showCamera = true
                        }
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .sheet(isPresented: $showCamera) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                ImagePicker(sourceType: .camera) { image in
                                    if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                                        cameraImage = image
                                        Task {
                                            await uploadImage(data: data)
                                            await fetchMediaItems()
                                        }
                                    }
                                }
                            } else {
                                VStack {
                                    Text("Camera not available on this device.")
                                    Button("Dismiss") {
                                        showCamera = false
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding()
                            }
                        }
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Upload Photo")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gold)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                await uploadImage(data: data)
                                await fetchMediaItems()
                            }
                        }
                    }

                    // Insert Edit Event button for host
                    if Auth.auth().currentUser?.uid == party.hostID {
                        NavigationLink(destination: EditPartyView(party: party, onSave: {})) {
                            Text("Edit Event")
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gold)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }

                    if !uploadStatus.isEmpty {
                        Text(uploadStatus)
                            .foregroundColor(uploadStatus.contains("✅") ? .green : .red)
                    }

                    Picker("Media Filter", selection: $showVaultedOnly) {
                        Text("Gallery").tag(false)
                        Text("Vault").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    let filteredItems = mediaItems.filter { showVaultedOnly ? $0.isVaulted : !$0.isVaulted }

                    if !filteredItems.isEmpty {
                        Text(showVaultedOnly ? "🔒 Vault" : "📷 Gallery")
                            .font(.headline)
                            .padding(.top)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)]) {
                            ForEach(filteredItems, id: \.url) { item in
                                VStack(spacing: 4) {
                                    if item.type == "image" {
                                        AsyncImage(url: URL(string: item.url)) { image in
                                            image.resizable()
                                                 .scaledToFill()
                                                 .frame(width: 100, height: 100)
                                                 .clipped()
                                                 .cornerRadius(8)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        Color.gray
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .overlay(
                                                Text("Video")
                                                    .foregroundColor(.white)
                                            )
                                    }

                                    Text(item.type.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text(showVaultedOnly ? "No vaulted media yet." : "No media uploaded yet.")
                            .foregroundColor(.gray)
                            .padding()
                    }

                    Spacer()
                }
                .padding(.bottom)
            }
            .background(Color.black)
            .navigationTitle(party.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Only show if presented modally, but for navigation stack, default back is shown
                    if canShowDismissButton() {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Back")
                        }
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                Task {
                    await fetchMediaItems()
                }
            }
            .sheet(isPresented: $showQRSheet) {
                VStack(spacing: 20) {
                    Text("Party QR Code")
                        .font(.title2)
                        .bold()

                    if let qrImage = generateQRCode(from: party.code) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }

                    Text("Party Code: \(party.code)")
                        .font(.headline)

                    Button("Close") {
                        showQRSheet = false
                    }
                }
                .padding()
            }
        }
    }

    // Helper to determine if we should show a dismiss button
    private func canShowDismissButton() -> Bool {
        // In a NavigationLink in a NavigationView, the system back button is shown by default.
        // If presented modally, .dismiss() is needed.
        // For now, always return false to avoid double back buttons in navigation stack.
        return false
    }

    func uploadImage(data: Data) async {
    guard let uid = Auth.auth().currentUser?.uid else {
        uploadStatus = "User not logged in."
        return
    }

    let db = Firestore.firestore()
    let fileName = UUID().uuidString + ".jpg"
    let storage = Storage.storage()
    let storageRef = storage.reference().child("parties/\(party.id)/media/\(fileName)")
    print("📤 Starting upload to: parties/\(party.id)/media/\(fileName)")

    do {
        print("📦 Uploading data...")
        _ = try await storageRef.putDataAsync(data, metadata: nil)
        print("✅ Upload complete")

        let downloadURL = try await storageRef.downloadURL()
        print("🌐 Download URL: \(downloadURL)")

        try await db.collection("parties").document(party.id).collection("media").addDocument(data: [
            "uploader_id": uid,
            "media_url": downloadURL.absoluteString,
            "timestamp_taken": Timestamp(date: Date()),
            "timestamp_uploaded": Timestamp(),
            "media_type": "image",
            "is_vaulted": false
        ])
        uploadStatus = "✅ Upload successful!"
    } catch {
        uploadStatus = "❌ Upload failed: \(error.localizedDescription)"
        print("❌ Upload failed: \(error)")
    }
    }

    func fetchMediaItems() async {
        let db = Firestore.firestore()
        let mediaCollection = db.collection("parties").document(party.id).collection("media")
        
        do {
            let snapshot = try await mediaCollection.getDocuments()
            var updatedItems: [(url: String, type: String, isVaulted: Bool)] = []
            
            for doc in snapshot.documents {
                let data = doc.data()
                guard let url = data["media_url"] as? String,
                      let type = data["media_type"] as? String,
                      let uploadedTimestamp = data["timestamp_uploaded"] as? Timestamp,
                      var isVaulted = data["is_vaulted"] as? Bool else { continue }
                
                let timeSinceUpload = Date().timeIntervalSince(uploadedTimestamp.dateValue())
                if timeSinceUpload > 86400 && !isVaulted {
                    try await mediaCollection.document(doc.documentID).updateData(["is_vaulted": true])
                    isVaulted = true
                }
                
                updatedItems.append((url: url, type: type, isVaulted: isVaulted))
            }
            
            mediaItems = updatedItems
        } catch {
            print("❌ Failed to fetch media items: \(error.localizedDescription)")
        }
    }
    func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        // Determine scale factors for high-resolution output (targeting a 300x300 image)
        let scaleX = 300 / outputImage.extent.size.width
        let scaleY = 300 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completionHandler: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completionHandler: completionHandler)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completionHandler: (UIImage?) -> Void

        init(completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            completionHandler(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
            picker.dismiss(animated: true)
        }
    }
}

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var selectedLocation: String = "All"
    @State private var selectedDate: Date = Date()
    @State private var selectedType: String = "All"
    @State private var allParties: [Party] = []
    @State private var filteredParties: [Party] = []

    let locations = ["All", "Houston", "New York", "Los Angeles"]
    let eventTypes = ["All", "Frat", "Birthday", "Club", "Other"]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextField("Search events...", text: $searchText)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.black)
                    .padding(.horizontal)

                Picker("Location", selection: $selectedLocation) {
                    ForEach(locations, id: \.self) { location in
                        Text(location)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .background(Color.black)

                Picker("Type", selection: $selectedType) {
                    ForEach(eventTypes, id: \.self) { type in
                        Text(type)
                            .foregroundColor(.white)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .background(Color.black)

                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.black)

                List(filteredParties) { party in
                    VStack(alignment: .leading) {
                        Text(party.name).font(.headline).foregroundColor(.white)
                        Text(party.location).font(.subheadline).foregroundColor(.white)
                        Text("Code: \(party.code)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color.black)
                }
                .background(Color.black)
            }
            .navigationTitle("Search Events")
            .background(Color.black)
            .colorScheme(.dark)
            .onAppear {
                fetchAllParties()
            }
            .onChange(of: searchText) { _ in filterParties() }
            .onChange(of: selectedLocation) { _ in filterParties() }
            .onChange(of: selectedType) { _ in filterParties() }
            .onChange(of: selectedDate) { _ in filterParties() }
        }
    }

    func fetchAllParties() {
        let db = Firestore.firestore()
        db.collection("parties").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                allParties = docs.compactMap { doc in
                    let data = doc.data()
                    let memberCount = (data["members"] as? [String])?.count ?? 1
                    let hostID = data["host_id"] as? String ?? ""
                    guard
                        let name = data["party_name"] as? String,
                        let code = data["party_code"] as? String,
                        let timestamp = data["created_at"] as? Timestamp
                  else {
                        let location = data["location"] as? String ?? "Unknown"
                        let imageURL = data["image_url"] as? String
                        return Party(
                            id: doc.documentID,
                            name: "Unnamed Party",
                            location: location,
                            code: "UNKNOWN",
                            createdAt: Date(),
                            imageURL: imageURL,
                            memberCount: memberCount,
                            hostID: hostID
                        )
                  }

                    let location = data["location"] as? String ?? "Unknown"
                    let imageURL = data["image_url"] as? String
                    return Party(
                        id: doc.documentID,
                        name: name,
                        location: location,
                        code: code,
                        createdAt: timestamp.dateValue(),
                        imageURL: imageURL,
                        memberCount: memberCount,
                        hostID: hostID
                    )
                }
                filterParties()
            }
        }
    }

    func filterParties() {
        filteredParties = allParties.filter { party in
            let matchesSearch = searchText.isEmpty || party.name.lowercased().contains(searchText.lowercased())
            let matchesLocation = selectedLocation == "All" || party.location == selectedLocation
            let matchesType = selectedType == "All" || party.name.lowercased().contains(selectedType.lowercased())
            let matchesDate = Calendar.current.isDate(party.createdAt, inSameDayAs: selectedDate)

            return matchesSearch && matchesLocation && matchesType && matchesDate
        }
    }
}

struct UserProfileView: View {
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var profileImageURL: String = ""
    @State private var uploads: [FeedItem] = []
    @State private var isEditingProfile = false
    @State private var followersCount: Int = 0
    @State private var followingCount: Int = 0
    @State private var hostedParties: [Party] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Header
                VStack(spacing: 12) {
                    if let url = URL(string: profileImageURL), !profileImageURL.isEmpty {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray.opacity(0.4))
                    }
 
                    Text(username.isEmpty ? "Unknown User" : username)
                        .font(.title2)
                        .bold()
 
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
 
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(followersCount)")
                                .font(.headline)
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        VStack {
                            Text("\(followingCount)")
                                .font(.headline)
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
 
                    Button("Edit Profile") {
                        isEditingProfile = true
                    }
                    .font(.subheadline)
                    .padding(.top, 4)
                    .foregroundColor(.blue)
                }
                .padding(.vertical)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black).shadow(radius: 2))
                .padding(.horizontal)
 
                Divider().padding(.horizontal)
 
                // Upload Grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Uploads")
                        .font(.headline)
                        .padding(.horizontal)
 
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(uploads) { item in
                            AsyncImage(url: URL(string: item.imageURL)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 110, height: 110)
                                    .clipped()
                                    .cornerRadius(6)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                                    .frame(width: 110, height: 110)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.black)
        .navigationTitle("Profile")
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(username: $username, bio: $bio, profileImageURL: $profileImageURL)
        }
        .onAppear {
            fetchProfile()
            fetchUploads()
            fetchHostedParties()
        }
    }

    func fetchHostedParties() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No user ID found.")
            return
        }
        let db = Firestore.firestore()
        db.collection("parties")
            .whereField("host_id", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    hostedParties = docs.compactMap { doc in
                        let data = doc.data()
                        let memberCount = (data["members"] as? [String])?.count ?? 1
                        let hostID = data["host_id"] as? String ?? ""
                        guard
                            let name = data["party_name"] as? String,
                            let code = data["party_code"] as? String,
                            let timestamp = data["created_at"] as? Timestamp
                        else {
                            return Party(
                                id: doc.documentID,
                                name: "Unnamed Party",
                                location: data["location"] as? String ?? "Unknown",
                                code: "UNKNOWN",
                                createdAt: Date(),
                                imageURL: data["image_url"] as? String,
                                memberCount: memberCount,
                                hostID: hostID
                            )
                        }

                        let location = data["location"] as? String ?? "Unknown"
                        return Party(
                            id: doc.documentID,
                            name: name,
                            location: location,
                            code: code,
                            createdAt: timestamp.dateValue(),
                            imageURL: data["image_url"] as? String,
                            memberCount: memberCount,
                            hostID: hostID
                        )
                    }
                }
            }
    }

    func deleteParty(_ party: Party) {
        let db = Firestore.firestore()
        db.collection("parties").document(party.id).delete { error in
            if let error = error {
                print("❌ Failed to delete party: \(error.localizedDescription)")
            } else {
                hostedParties.removeAll { $0.id == party.id }
            }
        }
    }

    func fetchProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                username = data["username"] as? String ?? ""
                bio = data["bio"] as? String ?? ""
                profileImageURL = data["profile_image_url"] as? String ?? ""
                followersCount = data["followers_count"] as? Int ?? 0
                followingCount = data["following_count"] as? Int ?? 0
            }
        }
    }

    func fetchUploads() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("parties")
            .whereField("members", arrayContains: uid)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                var allItems: [FeedItem] = []
                
                let group = DispatchGroup()
                
                for doc in docs {
                    let partyID = doc.documentID
                    group.enter()
                    db.collection("parties")
                        .document(partyID)
                        .collection("media")
                        .whereField("uploader_id", isEqualTo: uid)
                        .getDocuments { mediaSnap, _ in
                            if let mediaDocs = mediaSnap?.documents {
                                for mdoc in mediaDocs {
                                    let data = mdoc.data()
                                    guard let url = data["media_url"] as? String,
                                          let uploader = data["uploader_id"] as? String,
                                          let isVaulted = data["is_vaulted"] as? Bool else { continue }
                                    let likes = data["likes"] as? [String] ?? []
                                    allItems.append(FeedItem(id: mdoc.documentID, imageURL: url, uploaderID: uploader, isVaulted: isVaulted, partyID: partyID, likes: likes))
                                }
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    self.uploads = allItems
                }
            }
    }
    }
    
struct EditProfileView: View {
    @Binding var username: String
    @Binding var bio: String
    @Binding var profileImageURL: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Username")) {
                    TextField("Username", text: $username)
                }
                
                Section(header: Text("Bio")) {
                    TextField("Bio", text: $bio)
                }
                
                Section(header: Text("Profile Image URL")) {
                    TextField("Image URL", text: $profileImageURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "username": username,
            "bio": bio,
            "profile_image_url": profileImageURL
        ], merge: true)
    }
    
}




struct EditPartyView: View {
    var party: Party
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var location: String
    @State private var selectedImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil

    init(party: Party, onSave: @escaping () -> Void) {
        self.party = party
        self.onSave = onSave
        _name = State(initialValue: party.name)
        _location = State(initialValue: party.location)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // TextFields - white background for readability on black
                TextField("Party Name", text: $name)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.black)
                TextField("Location", text: $location)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .foregroundColor(.black)

                // PhotosPicker button - gold background, black text
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Select New Cover Photo")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gold)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }

                // Save Changes button - gold background, black text
                Button("Save Changes") {
                    saveChanges()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gold)
                .foregroundColor(.black)
                .cornerRadius(12)

                // Fetch and display current members
                MemberListView(partyID: party.id)
                    .frame(maxHeight: 300)

                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Edit Party")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gold)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gold)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .background(Color.black)
    }

    func saveChanges() {
        let db = Firestore.firestore()
        let ref = db.collection("parties").document(party.id)

        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            Task {
                var updates: [String: Any] = [
                    "party_name": name,
                    "location": location
                ]
                let storageRef = Storage.storage().reference().child("parties/\(party.id)/cover.jpg")
                do {
                    _ = try await storageRef.putDataAsync(data, metadata: nil)
                    let url = try await storageRef.downloadURL()
                    updates["image_url"] = url.absoluteString
                    try await ref.updateData(updates)
                    onSave()
                    dismiss()
                } catch {
                    print("❌ Failed to upload or update party: \(error)")
                }
            }
        } else {
            let initialUpdates: [String: Any] = [
                "party_name": name,
                "location": location
            ]
            ref.updateData(initialUpdates) { error in
                if error == nil {
                    onSave()
                    dismiss()
                }
            }
        }
    }
}

struct MemberListView: View {
    let partyID: String
    @State private var members: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Members")
                .font(.headline)

            if members.isEmpty {
                Text("No members found.")
                    .foregroundColor(.gray)
            } else {
                ForEach(members, id: \.self) { memberID in
                    HStack {
                        Text(memberID)
                            .font(.subheadline)
                        Spacer()
                        Button(role: .destructive) {
                            removeMember(memberID)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear(perform: fetchMembers)
    }

    func fetchMembers() {
        let db = Firestore.firestore()
        db.collection("parties").document(partyID).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let ids = data["members"] as? [String] {
                members = ids
            }
        }
    }

    func removeMember(_ uid: String) {
        let db = Firestore.firestore()
        db.collection("parties").document(partyID).updateData([
            "members": FieldValue.arrayRemove([uid]),
            "member_count": FieldValue.increment(Int64(-1))
        ]) { error in
            if error == nil {
                members.removeAll { $0 == uid }
            }
        }
    }
}
