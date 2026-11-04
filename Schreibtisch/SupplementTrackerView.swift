import SwiftUI
import SwiftData

/// Der Supplement-Tracker: Supplements anlegen und heute morgens / mittags / abends abhaken.
///
/// Die Haken gelten immer für den heutigen Tag. Am nächsten Tag ist die Liste
/// wieder leer – die alten Einnahmen bleiben aber gespeichert.
struct SupplementTrackerView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Supplement.createdAt) private var supplements: [Supplement]

    /// Ist das Fenster zum Anlegen eines Supplements offen?
    @State private var isAdding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tablettenbox")
                    .font(.title3.bold())
                Spacer()
                // Nur das +-Symbol; der Text dient Bedienungshilfen und dem Tooltip.
                Button("Supplement hinzufügen", systemImage: "plus") { isAdding = true }
                    .labelStyle(.iconOnly)
                    .help("Supplement hinzufügen")
            }
            .foregroundStyle(.white)

            Text("Heute, \(Date.now.formatted(date: .complete, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))

            // Ein Fach pro Tageszeit
            ForEach(DayTime.allCases) { time in
                PillCompartment(time: time) {
                    let planned = dueToday.filter { $0.isScheduled(at: time) }
                    if planned.isEmpty {
                        Text("leer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(planned) { supplement in
                            SupplementRow(
                                supplement: supplement,
                                isTaken: takenBinding(for: supplement, at: time),
                                onDelete: { delete(supplement) }
                            )
                        }
                    }
                }
            }

            if supplements.isEmpty {
                Text("Klicke auf +, um dein erstes Supplement einzusortieren.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Supplements, die heute nicht dran sind – mit dem nächsten Termin
            if !notDueToday.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heute nicht dran")
                        .font(.caption.bold())
                    ForEach(notDueToday) { supplement in
                        PausedRow(supplement: supplement,
                                  onDelete: { delete(supplement) })
                    }
                }
                .padding(10)
                .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        // Der Kunststoff-Korpus der Box
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.36, green: 0.55, blue: 0.75).gradient)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 5)
        }
        .environment(\.colorScheme, .light)
        // Ein "Sheet" ist ein Fenster, das von oben über die Ansicht gleitet.
        .sheet(isPresented: $isAdding) {
            AddSupplementSheet { supplement in
                modelContext.insert(supplement)
            }
        }
    }

    /// Supplements, die laut Intervall heute dran sind.
    private var dueToday: [Supplement] {
        supplements.filter { $0.isDue(on: .now) }
    }

    /// Supplements, die heute Pause haben.
    private var notDueToday: [Supplement] {
        supplements.filter { !$0.isDue(on: .now) }
    }

    private func delete(_ supplement: Supplement) {
        modelContext.delete(supplement)
    }

    /// Verbindet ein Häkchen mit den gespeicherten Einnahmen:
    /// Abhaken legt eine Einnahme für heute an, Haken entfernen löscht sie wieder.
    private func takenBinding(for supplement: Supplement, at time: DayTime) -> Binding<Bool> {
        Binding(
            get: { supplement.intake(on: .now, at: time) != nil },
            set: { isTaken in
                if isTaken {
                    let intake = SupplementIntake(day: .now, time: time)
                    modelContext.insert(intake)
                    intake.supplement = supplement
                } else if let intake = supplement.intake(on: .now, at: time) {
                    modelContext.delete(intake)
                }
            }
        )
    }
}

/// Ein Fach der Tablettenbox mit farbigem Deckel-Etikett.
private struct PillCompartment<Content: View>: View {
    let time: DayTime
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(time.title, systemImage: time.symbol)
                .font(.headline)
            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Das Fach: hell, mit leichtem Innenschatten-Effekt durch den Rand
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 2)
                }
        }
    }
}

/// Eine Zeile: Häkchen mit Name und Löschen-Knopf.
private struct SupplementRow: View {
    let supplement: Supplement
    @Binding var isTaken: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle(isOn: $isTaken) {
                Text(supplement.name)
                    .strikethrough(isTaken)
                    .foregroundStyle(isTaken ? .secondary : .primary)
            }
            .toggleStyle(.checkbox)

            if supplement.intervalDays > 1 {
                Text(Supplement.intervalText(supplement.intervalDays))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Löschen", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .contextMenu {
            Button("Supplement löschen", role: .destructive, action: onDelete)
        }
    }
}

/// Das Fenster zum Anlegen eines Supplements: Name, Tageszeiten und wie oft.
private struct AddSupplementSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (Supplement) -> Void

    @State private var name = ""
    @State private var morning = true
    @State private var noon = false
    @State private var evening = false
    @State private var interval = 1

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Hinzufügen geht nur mit Namen und mindestens einer Tageszeit.
    private var canAdd: Bool {
        !trimmedName.isEmpty && (morning || noon || evening)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Neues Supplement")
                .font(.title3.bold())

            TextField("Name, z. B. Vitamin D", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)

            Text("Wann nimmst du es?")
                .font(.headline)
            HStack(spacing: 16) {
                Toggle("Morgens", isOn: $morning)
                Toggle("Mittags", isOn: $noon)
                Toggle("Abends", isOn: $evening)
            }
            .toggleStyle(.checkbox)

            // Ein "Picker" ist ein Auswahlmenü.
            Picker("Wie oft?", selection: $interval) {
                ForEach(1...7, id: \.self) { days in
                    Text(Supplement.intervalText(days)).tag(days)
                }
            }
            .fixedSize()

            HStack {
                Spacer()
                Button("Abbrechen", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Hinzufügen", action: add)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canAdd)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private func add() {
        guard canAdd else { return }
        onAdd(Supplement(name: trimmedName,
                         takesMorning: morning,
                         takesNoon: noon,
                         takesEvening: evening,
                         intervalDays: interval))
        dismiss()
    }
}

/// Eine Zeile für ein Supplement, das heute Pause hat.
private struct PausedRow: View {
    let supplement: Supplement
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text(supplement.name)
                .foregroundStyle(.secondary)
            Text("\(Supplement.intervalText(supplement.intervalDays)) · wieder \(supplement.nextDueDate(after: .now).formatted(.dateTime.weekday(.wide).day().month()))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Löschen", systemImage: "trash", role: .destructive, action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .contextMenu {
            Button("Supplement löschen", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    SupplementTrackerView()
        .modelContainer(for: [Supplement.self, SupplementIntake.self], inMemory: true)
        .frame(width: 400, height: 500)
}
