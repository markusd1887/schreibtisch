import Foundation
import SwiftData

/// Eine Notiz, optional mit einer Erinnerung zu einem bestimmten Zeitpunkt.
@Model
final class Note {
    /// Die Überschrift, z. B. "Zahnarzt anrufen".
    var title: String
    /// Der eigentliche Notiztext (darf leer sein).
    var body: String
    /// Wann die Notiz angelegt wurde – damit sortieren wir die Liste.
    var createdAt: Date
    /// Zeitpunkt der Erinnerung. `nil` heißt: keine Erinnerung.
    var reminderDate: Date?
    /// Eine eindeutige Kennung für die Mitteilung dieser Notiz.
    /// Damit finden wir die geplante Mitteilung wieder, um sie zu ändern oder zu löschen.
    var notificationID: String

    init(title: String, body: String = "", reminderDate: Date? = nil, createdAt: Date = .now) {
        self.title = title
        self.body = body
        self.reminderDate = reminderDate
        self.createdAt = createdAt
        self.notificationID = UUID().uuidString
    }
}
