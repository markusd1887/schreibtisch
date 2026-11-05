import SwiftUI
import EventKit
import AppKit

/// Das Fenster "Neuer Termin", das sich über den +-Knopf am Tischkalender öffnet.
///
/// Der Termin wird direkt in deinem Mac-Kalender gespeichert – nicht in der App.
struct AddEventSheet: View {
    @Environment(CalendarStore.self) private var calendarStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var start = AddEventSheet.nextFullHour()
    @State private var durationMinutes = 60
    @State private var isAllDay = false
    @State private var calendarID: String?
    @State private var errorText: String?

    /// Auswahl für die Dauer (in Minuten).
    private let durations = [15, 30, 45, 60, 90, 120, 180]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Neuer Termin")
                .font(.title2.bold())

            // Ein "Form" ordnet Eingabefelder mit Beschriftung sauber untereinander an.
            Form {
                TextField("Titel", text: $title, prompt: Text("z. B. Zahnarzt"))

                Toggle("Ganztägig", isOn: $isAllDay)

                DatePicker("Beginn", selection: $start,
                           displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])

                if !isAllDay {
                    Picker("Dauer", selection: $durationMinutes) {
                        ForEach(durations, id: \.self) { minutes in
                            Text(Self.durationText(minutes)).tag(minutes)
                        }
                    }
                }

                Picker("Kalender", selection: $calendarID) {
                    ForEach(calendarStore.writableCalendars, id: \.calendarIdentifier) { calendar in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(Color(nsColor: calendar.color))
                            // Die Quelle (z. B. "iCloud") zeigt, ob der Termin aufs iPhone kommt.
                            Text("\(calendar.title) · \(calendar.source.title)")
                        }
                        .tag(Optional(calendar.calendarIdentifier))
                    }
                }
            }

            if let errorText {
                Text(errorText)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Abbrechen") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Hinzufügen") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 400)
        .onAppear {
            if calendarID == nil { calendarID = calendarStore.defaultCalendarID }
        }
    }

    private func save() {
        let calendar = Calendar.current
        let begin = isAllDay ? calendar.startOfDay(for: start) : start
        let end = isAllDay ? begin : begin.addingTimeInterval(TimeInterval(durationMinutes * 60))
        do {
            try calendarStore.addEvent(title: title.trimmingCharacters(in: .whitespaces),
                                       start: begin, end: end,
                                       isAllDay: isAllDay, calendarID: calendarID)
            dismiss()
        } catch {
            errorText = "Der Termin konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    /// Die nächste volle Stunde, z. B. 14:20 → 15:00.
    private static func nextFullHour() -> Date {
        let calendar = Calendar.current
        let now = Date.now
        let hourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? now
    }

    /// 30 → "30 Min.", 90 → "1,5 Std.", 120 → "2 Std."
    private static func durationText(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) Min." }
        let hours = Double(minutes) / 60
        return hours.formatted(.number.precision(.fractionLength(0...1))) + " Std."
    }
}
