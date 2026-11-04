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
    /// Auf welchem Tagesblatt die Aufgabe steht (immer 0:00 Uhr des Tages).
    ///
    /// Das Feld ist *optional* (`Date?`), weil ältere Aufgaben noch keinen Tag hatten.
    /// So kann SwiftData die bestehende Datenbank ohne eigenen Code anpassen
    /// ("leichte Migration"). Aufgaben ohne Tag bekommen beim Start "heute".
    var day: Date?

    init(title: String, day: Date, isDone: Bool = false, createdAt: Date = .now) {
        self.title = title
        self.day = Calendar.current.startOfDay(for: day)
        self.isDone = isDone
        self.createdAt = createdAt
    }

    /// Steht die Aufgabe auf dem Blatt dieses Tages?
    func belongs(to date: Date) -> Bool {
        guard let day else { return false }
        return Calendar.current.isDate(day, inSameDayAs: date)
    }

    /// Räumt die Aufgaben auf – wie beim Abschreiben auf ein neues Blatt:
    /// - Aufgaben ohne Tag (aus der Zeit vor dem Tagesblatt) kommen auf heute.
    /// - Unerledigte Aufgaben von vergangenen Tagen wandern auf heute.
    /// - Erledigte Aufgaben bleiben auf ihrem Tag.
    static func carryOver(in context: ModelContext, today: Date = .now) {
        let startOfToday = Calendar.current.startOfDay(for: today)
        // Ein "FetchDescriptor" beschreibt, welche Daten wir aus dem Speicher holen wollen.
        guard let all = try? context.fetch(FetchDescriptor<TodoItem>()) else { return }
        for todo in all {
            if let day = todo.day {
                if !todo.isDone && day < startOfToday {
                    todo.day = startOfToday
                }
            } else {
                todo.day = startOfToday
            }
        }
    }
}
