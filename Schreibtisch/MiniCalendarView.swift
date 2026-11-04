import SwiftUI
import SwiftData

/// Ein kleiner Monatskalender wie ein Tischkalender-Blatt.
///
/// - Ein Punkt unter dem Tag: Es gibt offene To-Dos.
/// - Eine kleine Glocke: Ein Klebezettel erinnert an diesem Tag.
/// - Klick auf einen Tag schlägt ihn auf der Unterlage auf.
struct MiniCalendarView: View {
    /// Der Tag, der auf der Unterlage aufgeschlagen ist (gehört der Hauptansicht).
    @Binding var selectedDay: Date

    @Query private var todos: [TodoItem]
    @Query private var notes: [Note]

    /// Der Monat, der gerade im Kalender zu sehen ist (erster Tag des Monats).
    @State private var month = MiniCalendarView.startOfMonth(.now)

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            header
            weekdayRow
            dayGrid
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .padding(.top, 18) // Platz für den Rand oben
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.notepadPaper)
                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
        }
        .overlay(alignment: .top) {
            // Bordeaux-Rand oben, wie bei einem Abreißkalender
            UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6)
                .fill(Color.bordeaux)
                .frame(height: 10)
        }
        .environment(\.colorScheme, .light)
        // Blättert man auf der Unterlage in einen anderen Monat, geht der Kalender mit.
        .onChange(of: selectedDay) { _, newDay in
            month = Self.startOfMonth(newDay)
        }
    }

    // MARK: Teile

    /// ‹ November 2026 ›
    private var header: some View {
        HStack {
            Button("Vorheriger Monat", systemImage: "chevron.left") { moveMonth(by: -1) }
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button("Nächster Monat", systemImage: "chevron.right") { moveMonth(by: 1) }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
    }

    /// Mo Di Mi … – in der Reihenfolge, die der Mac eingestellt hat (in Deutschland ab Montag).
    private var weekdayRow: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first...] + symbols[..<first])
        return HStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Das Gitter mit den Tagen. `LazyVGrid` ordnet Ansichten in Spalten an – hier 7 Spalten.
    private var dayGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        let openTodoDays = daysWithOpenTodos
        let reminderDays = daysWithReminders

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                if let date {
                    let key = calendar.startOfDay(for: date)
                    DayCell(date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDay),
                            isToday: calendar.isDateInToday(date),
                            hasTodos: openTodoDays.contains(key),
                            hasReminder: reminderDays.contains(key))
                        .onTapGesture { selectedDay = key }
                } else {
                    Color.clear.frame(height: 28) // leeres Feld vor dem 1. des Monats
                }
            }
        }
    }

    // MARK: Berechnungen

    /// Alle Felder des Monats: zuerst leere Felder (`nil`) bis zum passenden Wochentag,
    /// dann die Tage 1, 2, 3 …
    private var cells: [Date?] {
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<31
        let weekdayOfFirst = calendar.component(.weekday, from: month)
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let days: [Date?] = range.map { day in
            calendar.date(byAdding: .day, value: day - 1, to: month)
        }
        return Array(repeating: nil, count: leading) + days
    }

    /// Tage, an denen noch unerledigte Aufgaben stehen.
    /// Ein `Set` ist eine Sammlung ohne Doppelte – schnell zum Nachschauen.
    private var daysWithOpenTodos: Set<Date> {
        Set(todos.filter { !$0.isDone }.compactMap { $0.day.map(calendar.startOfDay(for:)) })
    }

    /// Tage, an denen ein Klebezettel eine Erinnerung hat.
    private var daysWithReminders: Set<Date> {
        Set(notes.compactMap { $0.reminderDate.map(calendar.startOfDay(for:)) })
    }

    private func moveMonth(by value: Int) {
        month = calendar.date(byAdding: .month, value: value, to: month)!
    }

    static func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
}

/// Ein einzelner Tag im Kalender.
private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTodos: Bool
    let hasReminder: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text(date.formatted(.dateTime.day()))
                .font(.caption.weight(isToday ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : (isToday ? Color.bordeaux : .primary))
                .frame(width: 22, height: 18)
                .background {
                    if isSelected {
                        Circle().fill(Color.bordeaux)
                    } else if isToday {
                        Circle().strokeBorder(Color.bordeaux.opacity(0.7), lineWidth: 1)
                    }
                }

            // Markierungen: Punkt für To-Dos, Glocke für Erinnerungen
            HStack(spacing: 2) {
                if hasTodos {
                    Circle().fill(Color.blue).frame(width: 4, height: 4)
                }
                if hasReminder {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.orange)
                }
            }
            .frame(height: 7)
        }
        .frame(maxWidth: .infinity, minHeight: 28)
        .contentShape(Rectangle()) // ganzes Feld ist klickbar
    }
}

#Preview {
    MiniCalendarView(selectedDay: .constant(Calendar.current.startOfDay(for: .now)))
        .modelContainer(for: [TodoItem.self, Note.self], inMemory: true)
        .frame(width: 250)
        .padding()
}
