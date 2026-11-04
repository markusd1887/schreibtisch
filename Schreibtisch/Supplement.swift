import Foundation
import SwiftData

/// Die drei Tageszeiten, zu denen man Supplements nehmen kann.
enum DayTime: String, CaseIterable, Identifiable {
    case morning, noon, evening

    var id: String { rawValue }

    /// Der Name, wie er in der App angezeigt wird.
    var title: String {
        switch self {
        case .morning: "Morgens"
        case .noon: "Mittags"
        case .evening: "Abends"
        }
    }

    /// Ein passendes Symbol (SF Symbols).
    var symbol: String {
        switch self {
        case .morning: "sunrise"
        case .noon: "sun.max"
        case .evening: "moon"
        }
    }
}

/// Ein Supplement, z. B. "Vitamin D", und wann man es nimmt.
@Model
final class Supplement {
    var name: String
    var takesMorning: Bool
    var takesNoon: Bool
    var takesEvening: Bool
    var createdAt: Date
    /// Alle wie viele Tage das Supplement genommen wird (1 = täglich, 7 = wöchentlich).
    /// Gezählt wird ab dem Tag, an dem es angelegt wurde.
    /// Der Standardwert `= 1` sorgt dafür, dass schon gespeicherte Supplements
    /// automatisch als "täglich" gelten.
    var intervalDays: Int = 1

    /// Alle erfassten Einnahmen dieses Supplements.
    /// Eine "Relationship" verknüpft zwei Modelle miteinander.
    /// `.cascade` heißt: Wird das Supplement gelöscht, verschwinden auch seine Einnahmen.
    @Relationship(deleteRule: .cascade, inverse: \SupplementIntake.supplement)
    var intakes: [SupplementIntake] = []

    init(name: String, takesMorning: Bool, takesNoon: Bool, takesEvening: Bool,
         intervalDays: Int = 1, createdAt: Date = .now) {
        self.name = name
        self.takesMorning = takesMorning
        self.takesNoon = takesNoon
        self.takesEvening = takesEvening
        self.intervalDays = intervalDays
        self.createdAt = createdAt
    }

    /// Text für das Intervall, z. B. "täglich" oder "alle 3 Tage".
    static func intervalText(_ days: Int) -> String {
        switch days {
        case 1: "täglich"
        case 2: "jeden 2. Tag"
        case 7: "wöchentlich"
        default: "alle \(days) Tage"
        }
    }

    /// Wie viele Tage seit dem Anlegen vergangen sind (nach Kalendertagen).
    private func daysSinceStart(until day: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: createdAt)
        let end = calendar.startOfDay(for: day)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// Ist das Supplement an diesem Tag dran?
    /// Beispiel "alle 3 Tage": am Tag des Anlegens, 3 Tage später, 6 Tage später …
    func isDue(on day: Date) -> Bool {
        let interval = max(intervalDays, 1)
        return daysSinceStart(until: day) % interval == 0
    }

    /// Der nächste Tag (ab morgen), an dem das Supplement wieder dran ist.
    func nextDueDate(after day: Date) -> Date {
        let calendar = Calendar.current
        var next = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: day))!
        while !isDue(on: next) {
            next = calendar.date(byAdding: .day, value: 1, to: next)!
        }
        return next
    }

    /// Wird das Supplement zu dieser Tageszeit genommen?
    func isScheduled(at time: DayTime) -> Bool {
        switch time {
        case .morning: takesMorning
        case .noon: takesNoon
        case .evening: takesEvening
        }
    }

    /// Die Einnahme für einen bestimmten Tag und eine Tageszeit – falls schon abgehakt.
    func intake(on day: Date, at time: DayTime) -> SupplementIntake? {
        intakes.first {
            Calendar.current.isDate($0.day, inSameDayAs: day) && $0.timeRaw == time.rawValue
        }
    }
}

/// Eine einzelne Einnahme: "An diesem Tag zu dieser Tageszeit genommen".
@Model
final class SupplementIntake {
    /// Der Tag der Einnahme (immer 0:00 Uhr des Tages).
    var day: Date
    /// Die Tageszeit als Text ("morning", "noon", "evening").
    /// Wir speichern den Text statt des Enums – das ist für SwiftData am einfachsten.
    var timeRaw: String
    /// Zu welchem Supplement die Einnahme gehört.
    var supplement: Supplement?

    init(day: Date, time: DayTime) {
        self.day = Calendar.current.startOfDay(for: day)
        self.timeRaw = time.rawValue
    }
}
