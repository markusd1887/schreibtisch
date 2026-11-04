import SwiftUI
import SwiftData
import AppKit

/// Das Herzstück: die Schreibunterlage mit dem Tagesblatt.
///
/// Oben steht das Datum mit Pfeilen zum Blättern, darunter
/// "Heute zu erledigen" und die linierten "Notizen zum Tag".
struct DayPageView: View {
    @Environment(\.modelContext) private var modelContext

    /// Der Tag, der gerade aufgeschlagen ist (immer 0:00 Uhr).
    /// `@Binding` heißt: Der Wert gehört der Hauptansicht und wird hier nur mitbenutzt.
    /// So können Unterlage und Monatskalender denselben Tag anzeigen.
    @Binding var day: Date

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            TodoListView(day: day)
                .frame(maxHeight: .infinity)

            DayNoteEditor(day: day)
                .frame(maxHeight: .infinity)
        }
        .padding(28)
        .background(DeskPadBackground())
        // Unerledigtes von gestern auf heute übertragen – beim Start …
        .task { TodoItem.carryOver(in: modelContext) }
        // … und wenn um Mitternacht ein neuer Tag beginnt.
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            let wasToday = Calendar.current.isDate(day, inSameDayAs: .now.addingTimeInterval(-3600))
            TodoItem.carryOver(in: modelContext)
            if wasToday { goToToday() } // Wer "heute" offen hatte, sieht auch das neue Heute.
        }
    }

    /// Kopfzeile: ‹ Datum › und der Knopf "Heute".
    private var header: some View {
        HStack(spacing: 12) {
            Button("Vorheriger Tag", systemImage: "chevron.left") { move(by: -1) }
                .labelStyle(.iconOnly)
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .help("Vorheriger Tag (⌘←)")

            VStack(alignment: .leading, spacing: 0) {
                Text(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.title.bold())
                Text(isToday ? "Heute" : day.formatted(.dateTime.year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Nächster Tag", systemImage: "chevron.right") { move(by: 1) }
                .labelStyle(.iconOnly)
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .help("Nächster Tag (⌘→)")

            Spacer()

            Button("Heute", action: goToToday)
                .disabled(isToday)
        }
        .buttonStyle(.bordered)
    }

    private func move(by days: Int) {
        day = Calendar.current.date(byAdding: .day, value: days, to: day)!
    }

    private func goToToday() {
        day = Calendar.current.startOfDay(for: .now)
    }
}

// MARK: - Notizen zum Tag

/// Ein freier, linierter Textbereich – ein Text pro Tag.
private struct DayNoteEditor: View {
    let day: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var dayNotes: [DayNote]

    /// Höhe einer Textzeile – danach richten sich die Linien.
    private static let font = NSFont.systemFont(ofSize: 14)
    private static let lineHeight = NSLayoutManager().defaultLineHeight(for: font)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notizen zum Tag")
                .font(.title3.bold())

            TextEditor(text: textBinding)
                .font(Font(Self.font))
                .scrollContentBackground(.hidden)
                .background(alignment: .top) {
                    RuledLines(lineHeight: Self.lineHeight)
                }
                .clipped()
        }
    }

    /// Die DayNote für den aufgeschlagenen Tag – falls schon etwas geschrieben wurde.
    private var note: DayNote? {
        dayNotes.first { Calendar.current.isDate($0.day, inSameDayAs: day) }
    }

    /// Verbindet das Textfeld mit dem Speicher.
    /// Erst beim ersten Tippen wird eine DayNote für den Tag angelegt.
    private var textBinding: Binding<String> {
        Binding(
            get: { note?.text ?? "" },
            set: { newText in
                if let note {
                    note.text = newText
                } else if !newText.isEmpty {
                    modelContext.insert(DayNote(day: day, text: newText))
                }
            }
        )
    }
}

/// Zeichnet blaue Linien wie auf liniertem Papier.
private struct RuledLines: View {
    let lineHeight: CGFloat

    var body: some View {
        Canvas { context, size in
            var y = lineHeight
            while y < size.height {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(.blue.opacity(0.18)), lineWidth: 1)
                y += lineHeight
            }
        }
    }
}

// MARK: - Unterlage

/// Die Schreibunterlage: ein Papierblock, unter dem man weitere Blätter sieht.
struct DeskPadBackground: View {
    var body: some View {
        ZStack {
            // Zwei Blätter darunter, leicht versetzt – wirkt wie ein Block
            paper.offset(x: 5, y: 6).brightness(-0.08)
            paper.offset(x: 2.5, y: 3).brightness(-0.04)
            paper
        }
        .overlay(alignment: .top) {
            // Der dunkle Leimrand oben am Block
            UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6)
                .fill(Color.leatherDark)
                .frame(height: 10)
        }
        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
    }

    private var paper: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.notepadPaper)
    }
}

#Preview {
    DayPageView(day: .constant(Calendar.current.startOfDay(for: .now)))
        .modelContainer(for: [TodoItem.self, DayNote.self], inMemory: true)
        .frame(width: 600, height: 650)
        .padding(30)
        .background(DeskBackground())
}
