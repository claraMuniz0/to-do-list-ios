/// Timing and motion rules for the Undo toast, kept pure so they can be tested without the view.
enum UndoToastPolicy {
    /// `nil` means the toast stays until Undo is used or a later delete replaces it: VoiceOver and Switch Control
    /// users cannot reliably reach a toast that disappears after 5 seconds, and Undo is the only way back from a delete.
    static func autoDismissDelay(assistiveTechnologyIsOn: Bool) -> Duration? {
        assistiveTechnologyIsOn ? nil : .seconds(5)
    }

    /// The Edit cover is still dismissing when the delete is reported; speaking sooner can be cut off by its focus change.
    static let announcementDelay: Duration = .milliseconds(600)

    static func slides(reduceMotion: Bool) -> Bool { !reduceMotion }
}
