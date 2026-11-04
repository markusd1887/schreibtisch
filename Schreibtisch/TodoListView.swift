import SwiftUI
import SwiftData

/// Die To-Dos eines Tages: Aufgaben anlegen, abhaken und löschen.
///
/// Die Ansicht sitzt auf dem Tagesblatt in der Mitte der Unterlage
/// und zeigt nur die Aufgaben des gerade aufgeschlagenen Tages.
struct TodoListView: View {
    /// Der Tag, dessen Aufgaben gezeigt werden.
    let day: Date

    /// `@Environment(\.modelContext)` gibt uns Zugriff auf den Speicher.
    /// Darüber fügen wir Aufgaben hinzu oder löschen sie.
    @Environment(\.modelContext) private var modelContext

    /// `@Query` holt alle gespeicherten Aufgaben und hält die Liste
    /// automatisch aktuell, sobald sich etwas ändert.
    /// Sortiert nach Erstellungsdatum (älteste oben).
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]

    /// Die Aufgaben dieses Tages: offene zuerst, erledigte rutschen nach unten.
    private var todos: [TodoItem] {
        let ofDay = allTodos.filter { $0.belongs(to: day) }
        return ofDay.filter { !$0.isDone } + ofDay.filter { $0.isDone }
    }

    /// Der Text im Eingabefeld für eine neue Aufgabe.
    @State private var newTitle = ""

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isToday ? "Heute zu erledigen" : "Zu erledigen")
                .font(.title3.bold())

            // Eingabezeile für neue Aufgaben
            HStack {
                TextField("Neue Aufgabe …", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTodo) // Enter-Taste fügt hinzu

                Button("Hinzufügen", systemImage: "plus", action: addTodo)
                    .disabled(trimmedTitle.isEmpty)
            }

            if todos.isEmpty {
                Text("Keine Aufgaben für diesen Tag.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
                Spacer(minLength: 0)
            } else {
                List {
                    ForEach(todos) { todo in
                        TodoRow(todo: todo, onDelete: { delete(todo) })
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden) // Papier scheint durch
            }
        }
    }

    private var trimmedTitle: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addTodo() {
        guard !trimmedTitle.isEmpty else { return }
        modelContext.insert(TodoItem(title: trimmedTitle, day: day))
        newTitle = ""
    }

    private func delete(_ todo: TodoItem) {
        modelContext.delete(todo)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todos[index])
        }
    }
}

/// Eine Zeile in der Liste: Haken, Titel und Löschen-Knopf.
private struct TodoRow: View {
    /// `@Bindable` erlaubt es, Eigenschaften des gespeicherten Objekts
    /// direkt zu ändern (z. B. `isDone`). SwiftData speichert das automatisch.
    @Bindable var todo: TodoItem
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle(isOn: $todo.isDone) {
                Text(todo.title)
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? .secondary : .primary)
            }
            .toggleStyle(.checkbox)

            Spacer()

            Button("Löschen", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .contextMenu {
            Button("Löschen", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    TodoListView(day: .now)
        // Für die Vorschau: ein Speicher nur im Arbeitsspeicher (nicht auf der Festplatte).
        .modelContainer(for: TodoItem.self, inMemory: true)
        .frame(width: 400, height: 400)
        .padding()
}
