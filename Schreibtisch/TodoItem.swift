import Foundation
import SwiftData

/// Eine einzelne Aufgabe.
///
/// `@Model` sagt SwiftData: "Diese Klasse soll dauerhaft gespeichert werden."
/// SwiftData legt dafür automatisch eine kleine Datenbank auf dem Mac an.
@Model
final class TodoItem {
    /// Der Text der Aufgabe, z. B. "Einkaufen gehen".
    var title: String
    /// Ist die Aufgabe erledigt (abgehakt)?
    var isDone: Bool
    /// Wann die Aufgabe angelegt wurde – damit sortieren wir die Liste.
    var createdAt: Date

    init(title: String, isDone: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
