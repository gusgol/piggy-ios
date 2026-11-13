import Foundation
import FirebaseFirestore

extension Query {
    /// Live query results as an `AsyncThrowingStream`, mapped to domain models.
    ///
    /// The SDK already offers `query.snapshots` (an AsyncSequence of raw `QuerySnapshot`s), and you'd
    /// use it directly in code that's happy to depend on Firestore. Here the repository protocols
    /// promise a concrete `AsyncThrowingStream<[Model], Error>` so that ViewModels never see Firestore
    /// types, and wrapping the listener is the simplest way to produce that.
    ///
    /// Same shape as `FirebaseAuthRepository.authState()`: the listener yields into the continuation,
    /// and `onTermination` removes it when the consuming Task (a view's `.task`) is cancelled.
    func stream<Model>(_ transform: @escaping (QuerySnapshot) -> Model) -> AsyncThrowingStream<Model, Error> {
        AsyncThrowingStream { continuation in
            let registration = addSnapshotListener { snapshot, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let snapshot {
                    continuation.yield(transform(snapshot))
                }
            }
            continuation.onTermination = { _ in
                registration.remove()
            }
        }
    }
}
