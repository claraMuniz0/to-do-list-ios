import Foundation

extension TodoItemSortOrder {
    /// Menu text, also read by VoiceOver.
    var title: String {
        switch self {
        case .dueDate: "Due date"
        case .newestFirst: "Newest first"
        case .titleAZ: "Title A to Z"
        }
    }
}
