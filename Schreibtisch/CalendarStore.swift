import SwiftUI
import EventKit
import AppKit

/// Die Verbindung zu deinem Mac-Kalender.
///
/// **EventKit** ist Apples Baustein für Kalender und Erinnerungen. Die App liest
/// darüber die Termine, die ohnehin auf deinem Mac sind. Um iCloud kümmert sich
/// macOS selbst: Was auf dem iPhone eingetragen wird, landet automatisch auch hier.
///
/// `@Observable` bedeutet: Ändern sich `access` oder `events`, zeichnen sich
/// alle Ansichten, die diese Werte benutzen, von selbst neu.
@Observable
final class CalendarStore {
    /// Darf die App auf den Kalender zugreifen?
    enum Access {
        /// Noch nicht gefragt – der Nutzer muss erst auf "Kalender verbinden" klicken.
        case notAsked
        case granted
        /// Abgelehnt (lässt sich in den Systemeinstellungen ändern).
        case denied
    }

    private(set) var access: Access
    /// Alle Termine von heute bis `daysAhead` Tage voraus, nach Beginn sortiert.
    private(set) var events: [EKEvent] = []

    /// Wie viele Tage ab heute geladen werden.
    let daysAhead = 4

    /// Markierungen für den Wandkalender: Tag (0:00 Uhr) → Farbe des ersten Termins an dem Tag.
    private(set) var monthMarks: [Date: Color] = [:]
    /// Der Monat, den der Wandkalender gerade zeigt.
    @ObservationIgnored private var markedMonth: Date?

    @ObservationIgnored private let store = EKEventStore()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init() {
        access = Self.currentAccess()
        if access == .granted { reload() }

        // Neu laden, wenn sich im Kalender etwas ändert (z. B. ein Termin vom iPhone) …
        observers.append(NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        })
        // … und um Mitternacht, damit "Heute" stimmt.
        observers.append(NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        })
    }

    /// Fragt nur nach dem aktuellen Stand – löst keine Abfrage aus.
    private static func currentAccess() -> Access {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: .granted
        case .notDetermined: .notAsked
        default: .denied // abgelehnt, eingeschränkt oder nur Schreibzugriff
        }
    }

    /// Zeigt die macOS-Abfrage "Schreibtisch möchte auf deine Kalender zugreifen".
    func requestAccess() async {
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        access = granted ? .granted : .denied
        if granted { reload() }
    }

    func reload() {
        guard access == .granted else { return }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: daysAhead, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        reloadMarks()
    }

    /// Der Wandkalender meldet hier, welchen Monat er zeigt (erster Tag des Monats).
    func loadMarks(forMonth month: Date) {
        markedMonth = month
        reloadMarks()
    }

    /// Sucht alle Tage im angezeigten Monat, an denen mindestens ein Termin stattfindet.
    /// Mehrtägige Termine markieren jeden ihrer Tage.
    private func reloadMarks() {
        guard access == .granted, let month = markedMonth else {
            monthMarks = [:]
            return
        }
        let calendar = Calendar.current
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: month)!
        let predicate = store.predicateForEvents(withStart: month, end: monthEnd, calendars: nil)
        let monthEvents = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }

        var marks: [Date: Color] = [:]
        for event in monthEvents {
            var day = calendar.startOfDay(for: max(event.startDate, month))
            // `repeat` statt `while`: Auch ein Termin ohne Dauer markiert seinen Tag.
            repeat {
                if marks[day] == nil {
                    marks[day] = Color(nsColor: event.calendar.color)
                }
                day = calendar.date(byAdding: .day, value: 1, to: day)!
            } while day < event.endDate && day < monthEnd
        }
        monthMarks = marks
    }

    /// Die Termine, die an einem bestimmten Tag stattfinden.
    func events(on day: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return events.filter { $0.startDate < dayEnd && $0.endDate > dayStart }
    }
}
