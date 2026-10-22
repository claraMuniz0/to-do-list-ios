import Foundation

/// Stored shape of a `Step`: plain values, so a corrupt title is caught by the mapper and never by Domain.
struct StepDTO: Codable, Equatable {
    var id: UUID
    var title: String
    var isDone: Bool
}
