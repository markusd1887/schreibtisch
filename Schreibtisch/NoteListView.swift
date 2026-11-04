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
                Text("Notizen")
                    .font(.title2.bold())
                Spacer()
                Button("Neue Notiz", systemImage: "plus") { isCreating = true }
            }

            if notes.isEmpty {
                ContentUnavailableView(
                    "Keine Notizen",
                    systemImage: "note.text",
                    description: Text("Lege oben deine erste Notiz an.")
                )
            } else {
                List {
                    ForEach(notes) { note in
                        NoteRow(note: note,
                                onEdit: { editingNote = note },
                                onDelete: { delete(note) })
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden) // Papier der Karte scheint durch
            }
        }
        .padding()
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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            delete(notes[index])
        }
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
