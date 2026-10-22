import Foundation

/// One suggested step in the sheet: the user can untick it or edit its text before it is added.
struct SuggestedStep: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var isSelected = true
}

/// Where a Claude step suggestion is: not asked, waiting, ready to pick from, nothing to offer, or failed.
enum StepSuggestionState: Equatable {
    case idle
    case loading
    case suggestions([SuggestedStep])
    /// Claude answered but every suggestion was a repeat or invalid.
    case empty
    case failed(StepSuggestionError)
}
