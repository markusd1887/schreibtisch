import SwiftUI
import EventKit
import AppKit

/// Das kleine Fenster, das sich beim Klick auf einen markierten Tag im Wandkalender öffnet.
///
/// Ein "Popover" ist ein kleines Fenster mit Pfeil, das an einer Stelle "klebt"
/// und sich schließt, sobald man daneben klickt.
///
/// Es zeigt alles, wofür der Tag eine Markierung hat:
/// Termine (Strich), offene Aufgaben (Punkt) und Erinnerungen (Glocke).
struct DayDetailPopover: View {
    let day: Date
    let events: [EKEvent]
    let todos: [TodoItem]
    let reminders: [Note]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.headline)

            if !events.isEmpty {
                section("Termine", systemImage: "calendar") {
                    ForEach(events, id: \.self) { event in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle()
                                .fill(Color(nsColor: event.calendar.color))
                                .frame(width: 7, height: 7)
                            Text(timeText(for: event))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text(event.title ?? "Ohne Titel")
                        }
                    }
                }
            }

            if !todos.isEmpty {
                section("Offene Aufgaben", systemImage: "checklist") {
                    ForEach(todos) { todo in
                        Label(todo.title, systemImage: "circle")
                    }
                }
            }

            if !reminders.isEmpty {
                section("Erinnerungen", systemImage: "bell") {
                    ForEach(reminders) { note in
                        HStack(spacing: 6) {
                            Text(note.reminderDate?.formatted(date: .omitted, time: .shortened) ?? "")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Text(note.title)
                        }
                    }
                }
            }

            if events.isEmpty && todos.isEmpty && reminders.isEmpty {
                Text("Nichts eingetragen.")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .padding(14)
        .frame(width: 260, alignment: .leading)
    }

    /// Eine Überschrift mit Symbol und darunter die Einträge.
    private func section<Content: View>(_ title: String, systemImage: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content()
        }
    }

    /// "09:30 – 10:30", "ganztägig" oder bei mehrtägigen Terminen "läuft".
    private func timeText(for event: EKEvent) -> String {
        if event.isAllDay { return "ganztägig" }
        let calendar = Calendar.current
        if event.startDate < calendar.startOfDay(for: day) { return "läuft" }
        let start = event.startDate.formatted(date: .omitted, time: .shortened)
        let end = event.endDate.formatted(date: .omitted, time: .shortened)
        return calendar.isDate(event.endDate, inSameDayAs: day) ? "\(start) – \(end)" : start
    }
}
