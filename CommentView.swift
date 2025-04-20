import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Foundation

struct CommentView: View {
    let partyID: String
    let mediaID: String

    @State private var newComment: String = ""
    @State private var comments: [Comment] = []
    @State private var replyingTo: Comment? = nil
    @State private var userID: String = Auth.auth().currentUser?.uid ?? ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if comments.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "text.bubble")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No comments yet.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(parentComments()) { comment in
                                Section {
                                    CommentRow(comment: comment, onReply: {
                                        replyingTo = comment
                                    })

                                    ForEach(childComments(parentID: comment.id)) { reply in
                                        CommentRow(comment: reply, isReply: true, onReply: {
                                            replyingTo = reply
                                        })
                                    }
                                }
                                .id(comment.id)
                            }
                            .onDelete(perform: deleteComment)
                        }
                        .onChange(of: comments.count) { _ in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if let last = comments.last {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    TextField(replyingTo != nil ? "Replying to \(replyingTo!.username)..." : "Add a comment...", text: $newComment)
                        .textFieldStyle(.roundedBorder)

                    Button("Post") {
                        Task {
                            await postComment()
                        }
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let db = Firestore.firestore()
                let query = db.collection("parties")
                    .document(partyID)
                    .collection("media")
                    .document(mediaID)
                    .collection("comments")
                    .order(by: "timestamp", descending: false)

                query.addSnapshotListener { snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ Failed to listen for comments: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    comments = documents.compactMap { doc in
                        let data = doc.data()
                        guard let text = data["text"] as? String,
                              let username = data["username"] as? String,
                              let timestamp = data["timestamp"] as? Timestamp,
                              let userID = data["user_id"] as? String else {
                            return nil
                        }
                        let parentID = data["parent_id"] as? String
                        return Comment(id: doc.documentID, username: username, text: text, timestamp: timestamp.dateValue(), userID: userID, parentID: parentID)
                    }
                }
            }
        }
    }

    func parentComments() -> [Comment] {
        comments.filter { $0.parentID == nil }
    }

    func childComments(parentID: String) -> [Comment] {
        comments.filter { $0.parentID == parentID }
    }

    func postComment() async {
        guard !userID.isEmpty else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        let userDoc = try? await userRef.getDocument()

        let username = userDoc?.data()?["username"] as? String ?? "Unknown"

        var commentData: [String: Any] = [
            "text": newComment,
            "timestamp": Timestamp(),
            "user_id": userID,
            "username": username
        ]

        if let replying = replyingTo {
            commentData["parent_id"] = replying.id
        }

        do {
            try await db.collection("parties")
                .document(partyID)
                .collection("media")
                .document(mediaID)
                .collection("comments")
                .addDocument(data: commentData)

            // Notification logic
            let recipientID: String
            let message: String

            if let replying = replyingTo {
                recipientID = replying.userID
                message = "\(username) replied to your comment"
            } else {
                // Fetch uploader ID for the media
                let mediaDoc = try? await db.collection("parties").document(partyID).collection("media").document(mediaID).getDocument()
                recipientID = mediaDoc?.data()?["uploader_id"] as? String ?? ""
                message = "\(username) commented on your post"
            }

            if recipientID != userID && !recipientID.isEmpty {
                let notification: [String: Any] = [
                    "recipient_id": recipientID,
                    "sender_id": userID,
                    "message": message,
                    "timestamp": Timestamp()
                ]
                try? await db.collection("notifications").addDocument(data: notification)
            }

            newComment = ""
            replyingTo = nil
        } catch {
            print("❌ Failed to post comment: \(error)")
        }
    }

    func deleteComment(at offsets: IndexSet) {
        for index in offsets {
            let comment = parentComments()[index]
            guard comment.userID == userID else { continue }

            let db = Firestore.firestore()
            db.collection("parties")
                .document(partyID)
                .collection("media")
                .document(mediaID)
                .collection("comments")
                .document(comment.id)
                .delete { error in
                    if let error = error {
                        print("❌ Failed to delete comment: \(error.localizedDescription)")
                    }
                }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    var isReply: Bool = false
    var onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.username)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: onReply) {
                    Text("Reply")
                }
                .buttonStyle(.plain)
                .font(.caption2)
            }

            Text(comment.text)
        }
        .padding(.leading, isReply ? 24 : 0)
        .padding(.vertical, 4)
    }
}

struct Comment: Identifiable {
    let id: String
    let username: String
    let text: String
    let timestamp: Date
    let userID: String
    let parentID: String?
}
