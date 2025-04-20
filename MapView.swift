import SwiftUI
import MapKit
import FirebaseFirestore

struct PartyMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var mapAnnotations: [PartyMapAnnotation] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("🗺️ Party Map")
                .font(.largeTitle)
                .bold()

            Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        Text(annotation.party.name)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(6)
                    }
                }
            }
            .frame(height: 400)
            .cornerRadius(12)
            .padding()
        }
        .onAppear {
            fetchParties()
        }
    }

    func fetchParties() {
        let db = Firestore.firestore()
        db.collection("parties").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                let parties = docs.compactMap { doc -> PartyMapAnnotation? in
                    let data = doc.data()
                    guard
                        let name = data["party_name"] as? String,
                        let code = data["party_code"] as? String,
                        let timestamp = data["created_at"] as? Timestamp
                    else { return nil }

                    let location = data["location"] as? String ?? "Unknown"
                    let party = Party(
                        id: doc.documentID,
                        name: name,
                        location: location,
                        code: code,
                        createdAt: timestamp.dateValue()
                    )

                    let dummyCoordinates = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                    return PartyMapAnnotation(party: party, coordinate: dummyCoordinates)
                }

                self.mapAnnotations = parties
            }
        }
    }
}
