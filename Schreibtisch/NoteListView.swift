import SwiftUI
import SwiftData

/// Die Notizen-Liste: Notizen anlegen, bearbeiten, löschen – optional mit Erinnerung.
///
/// Wie die To-Do-Liste ist auch diese Ansicht in sich abgeschlossen
/// und kann später als Kachel ins Dashboard wandern.
struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext

    /// Neueste Notiz oben.
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    /// Die Notiz, die gerade im Bearbeiten-Fenster offen ist.
    @State private var editingNote: Note?
    /// Ist das Fenster für eine *neue* Notiz offen?
    @State private var isCreating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Klebezettel")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                Spacer()
                Button("Neuer Zettel", systemImage: "plus") { isCreating = true }
                    .labelStyle(.iconOnly)
                    .help("Neuer Klebezettel")
            }

            if notes.isEmpty {
                // Ein leerer Zettel als Hinweis
                StickyNote(index: 0) {
                    Text("Noch keine Zettel.\nKlicke auf +, um einen anzukleben.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onTapGesture { isCreating = true }
                Spacer(minLength: 0)
            } else {
                // Eine "ScrollView" macht den Bereich scrollbar, wenn viele Zettel da sind.
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                            StickyNote(index: index) {
                                NoteRow(note: note,
                                        onEdit: { editingNote = note },
                                        onDelete: { delete(note) })
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .scrollIndicators(.never)
            }
        }
        // Fenster zum Bearbeiten einer bestehenden Notiz
        .sheet(item: $editingNote) { note in
            NoteEditor(note: note) { title, body, reminder in
                note.title = title
                note.body = body
                note.reminderDate = reminder
                ReminderScheduler.update(for: note)
            }
        }
        // Fenster für eine neue Notiz
        .sheet(isPresented: $isCreating) {
            NoteEditor(note: nil) { title, body, reminder in
                let note = Note(title: title, body: body, reminderDate: reminder)
                modelContext.insert(note)
                ReminderScheduler.update(for: note)
            }
        }
    }

    private func delete(_ note: Note) {
        ReminderScheduler.cancel(for: note)
        modelContext.delete(note)
    }

}

/// Ein einzelner Klebezettel: farbiges Quadrat mit Schatten, leicht schräg.
private struct StickyNote<Content: View>: View {
    /// Position in der Liste – damit nicht alle Zettel gleich aussehen.
    let index: Int
    @ViewBuilder let content: Content

    private static var colors: [Color] { [
        Color(red: 1.0, green: 0.93, blue: 0.55),   // gelb
        Color(red: 1.0, green: 0.80, blue: 0.85),   // rosa
        Color(red: 0.75, green: 0.92, blue: 0.78),  // grün
        Color(red: 0.78, green: 0.88, blue: 1.0)    // blau
    ] }
    private static var angles: [Double] { [-1.5, 1.2, -0.6, 1.8] }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background {
                Rectangle()
                    .fill(Self.colors[index % Self.colors.count].gradient)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 3)
            }
            .rotationEffect(.degrees(Self.angles[index % Self.angles.count]))
            .environment(\.colorScheme, .light) // Papier bleibt hell
    }
}

/// Eine Zeile: Titel, Textvorschau, ggf. Erinnerung, Löschen-Knopf.
private struct NoteRow: View {
    let note: Note
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                if !note.body.isEmpty {
                    Text(note.body)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
                if let date = note.reminderDate {
                    Label(date.formatted(date: .abbreviated, time: .shortened),
                          systemImage: date > .now ? "bell" : "bell.slash")
                        .font(.caption)
                        .foregroundStyle(date > .now ? Color.accentColor : .secondary)
                }
            }
            Spacer()
            Button("Löschen", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .contentShape(Rectangle())   // ganze Zeile ist klickbar
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button("Bearbeiten", action: onEdit)
            Button("Löschen", role: .destructive, action: onDelete)
        }
    }
}

/// Das Fenster zum Anlegen oder Bearbeiten einer Notiz.
///
/// Wir arbeiten auf einer Kopie der Werte (`@State`). Erst "Sichern" übernimmt sie –
/// so kann man mit "Abbrechen" ohne Änderungen zurück.
private struct NoteEditor: View {
    @Environment(\.dismiss) private var dismiss

    let isNew: Bool
    let onSave: (_ title: String, _ body: String, _ reminder: Date?) -> Void

    @State private var title: String
    @State private var text: String
    @State private var hasReminder: Bool
    @State private var reminderDate: Date

    init(note: Note?, onSave: @escaping (String, String, Date?) -> Void) {
        self.isNew = note == nil
        self.onSave = onSave
        _title = State(initialValue: note?.title ?? "")
        _text = State(initialValue: note?.body ?? "")
        _hasReminder = State(initialValue: note?.reminderDate != nil)
        // Vorschlag für eine neue Erinnerung: in einer Stunde
        _reminderDate = State(initialValue: note?.reminderDate ?? .now.addingTimeInterval(3600))
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isNew ? "Neue Notiz" : "Notiz bearbeiten")
                .font(.title3.bold())

            TextField("Titel", text: $title)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 120)
                .border(.separator)

            Toggle("Erinnerung", isOn: $hasReminder)
                .onChange(of: hasReminder) { _, isOn in
                    if isOn { ReminderScheduler.requestAuthorization() }
                }

            if hasReminder {
                DatePicker("Zeitpunkt", selection: $reminderDate, in: Date.now...)
                if reminderDate <= .now {
                    Text("Der Zeitpunkt liegt in der Vergangenheit – es kommt keine Mitteilung.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            HStack {
                Spacer()
                Button("Abbrechen", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Sichern") {
                    onSave(trimmedTitle, text, hasReminder ? reminderDate : nil)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    NoteListView()
        .modelContainer(for: Note.self, inMemory: true)
        .frame(width: 400, height: 400)
}
