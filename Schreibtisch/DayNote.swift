import Foundation
import SwiftData

/// Die freien "Notizen zum Tag" auf dem Tagesblatt – ein Text pro Tag.
@Model
final class DayNote {
    /// Der Tag (immer 0:00 Uhr). `.unique` heißt: Pro Tag gibt es höchstens eine DayNote.
    @Attribute(.unique) var day: Date
    /// Der Text, den man auf das Blatt schreibt.
    var text: String

    init(day: Date, text: String = "") {
        self.day = Calendar.current.startOfDay(for: day)
        self.text = text
    }
}
