import Foundation

/// Loading state for a screen backed by a live listener. Shared by the Expenses and Categories ViewModels.
nonisolated enum LoadState: Equatable, Sendable {
    case loading
    case loaded
    case failed(message: String)
}
