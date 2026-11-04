import SwiftUI
import EventKit
import AppKit

/// Der Tischkalender: ein kleiner Aufstellkalender mit deinen echten Terminen.
///
/// Oben die Ringbindung, darunter das Blatt mit "Heute" und den nächsten Tagen,
/// unten der Standfuß. Die Termine kommen aus dem Mac-Kalender (siehe `CalendarStore`).
struct DeskCalendarView: View {
    @Environment(CalendarStore.self) private var calendarStore

    var body: some View {
        VStack(spacing: 0) {
            RingBinding()
                .zIndex(1)

            VStack(alignment: .leading, spacing: 0) {
                header
                content
                    .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.notepadPaper)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.top, -6) // die Ringe greifen ins Blatt

            // Der Standfuß
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [.leather, .leatherDark], startPoint: .top, endPoint: .bottom))
                .frame(height: 10)
                .padding(.horizontal, -8)
        }
        .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
        .environment(\.colorScheme, .light) // Papier bleibt hell
    }

    /// Bordeaux-Streifen mit dem heutigen Datum.
    private var header: some View {
        HStack {
            Image(systemName: "calendar")
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bordeaux)
    }

    @ViewBuilder
    private var content: some View {
        switch calendarStore.access {
        case .notAsked:
            VStack(alignment: .leading, spacing: 8) {
                Text("Zeig hier deine Termine aus dem Mac-Kalender.")
                    .font(.callout)
                Button("Kalender verbinden") {
                    Task { await calendarStore.requestAccess() }
                }
            }
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text("Kein Zugriff auf den Kalender. Du kannst ihn in den Systemeinstellungen erlauben.")
                    .font(.callout)
                Button("Einstellungen öffnen") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                }
            }
        case .granted:
            agenda
        }
    }

    /// Heute ausführlich, die nächsten Tage kurz.
    private var agenda: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let todayEvents = calendarStore.events(on: today)
        let upcoming = (1..<calendarStore.daysAhead).compactMap { offset -> (Date, [EKEvent])? in
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            let list = calendarStore.events(on: day)
            return list.isEmpty ? nil : (day, list)
        }

        return VStack(alignment: .leading, spacing: 6) {
            if todayEvents.isEmpty {
                Text("Heute keine Termine")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayEvents.prefix(4), id: \.self) { event in
                    EventRow(event: event, day: today)
                }
                if todayEvents.count > 4 {
                    Text("+ \(todayEvents.count - 4) weitere")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !upcoming.isEmpty {
                Divider().padding(.vertical, 2)
                ForEach(upcoming, id: \.0) { day, list in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.formatted(.dateTime.weekday(.wide).day().month()))
                            .font(.caption.bold())
                            .foregroundStyle(Color.bordeaux)
                        ForEach(list.prefix(2), id: \.self) { event in
                            EventRow(event: event, day: day, compact: true)
                        }
                        if list.count > 2 {
                            Text("+ \(list.count - 2) weitere")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

/// Eine Terminzeile: farbiger Punkt (Farbe des Kalenders), Uhrzeit, Titel.
private struct EventRow: View {
    let event: EKEvent
    /// Der Tag, unter dem der Termin steht – wichtig für mehrtägige Termine.
    let day: Date
    var compact = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle()
                .fill(Color(nsColor: event.calendar.color))
                .frame(width: 7, height: 7)
            Text(timeText)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: compact ? 38 : 42, alignment: .leading)
            Text(event.title ?? "Ohne Titel")
                .lineLimit(1)
        }
        .font(compact ? .caption : .callout)
    }

    private var timeText: String {
        // Ganztägig, oder der Termin hat schon an einem früheren Tag begonnen
        if event.isAllDay || event.startDate < Calendar.current.startOfDay(for: day) {
            return "ganzt."
        }
        return event.startDate.formatted(date: .omitted, time: .shortened)
    }
}

/// Die Ringbindung oben am Kalender: kleine Messing-Ringe.
private struct RingBinding: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach(0..<9, id: \.self) { _ in
                Capsule()
                    .strokeBorder(Color.brass, lineWidth: 2)
                    .frame(width: 7, height: 14)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    DeskCalendarView()
        .environment(CalendarStore())
        .frame(width: 250)
        .padding(30)
        .background(DeskBackground())
}
