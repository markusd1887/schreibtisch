import SwiftUI
import SwiftData

/// Der Supplement-Tracker: Supplements anlegen und heute morgens / mittags / abends abhaken.
///
/// Die Haken gelten immer für den heutigen Tag. Am nächsten Tag ist die Liste
/// wieder leer – die alten Einnahmen bleiben aber gespeichert.
struct SupplementTrackerView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Supplement.createdAt) private var supplements: [Supplement]

    // Eingaben für ein neues Supplement
    @State private var newName = ""
    @State private var newMorning = true
    @State private var newNoon = false
    @State private var newEvening = false
    @State private var newInterval = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supplements")
                .font(.title2.bold())

            // Eingabe für neue Supplements
            HStack {
                TextField("Neues Supplement …", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addSupplement)
                Button("Hinzufügen", systemImage: "plus", action: addSupplement)
                    .disabled(!canAdd)
            }
            HStack {
                Toggle("Morgens", isOn: $newMorning)
                Toggle("Mittags", isOn: $newNoon)
                Toggle("Abends", isOn: $newEvening)
            }
            .toggleStyle(.checkbox)

            // Wie oft? Ein "Picker" ist ein Auswahlmenü.
            Picker("Wie oft:", selection: $newInterval) {
                ForEach(1...7, id: \.self) { days in
                    Text(Supplement.intervalText(days)).tag(days)
                }
            }
            .fixedSize()

            if supplements.isEmpty {
                ContentUnavailableView(
                    "Keine Supplements",
                    systemImage: "pills",
                    description: Text("Lege oben dein erstes Supplement an.")
                )
            } else {
                List {
                    Text("Heute, \(Date.now.formatted(date: .complete, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(DayTime.allCases) { time in
                        let planned = dueToday.filter { $0.isScheduled(at: time) }
                        if !planned.isEmpty {
                            Section {
                                ForEach(planned) { supplement in
                                    SupplementRow(
                                        supplement: supplement,
                                        isTaken: takenBinding(for: supplement, at: time),
                                        onDelete: { delete(supplement) }
                                    )
                                }
                            } header: {
                                Label(time.title, systemImage: time.symbol)
                            }
                        }
                    }

                    // Supplements, die heute nicht dran sind – mit dem nächsten Termin
                    if !notDueToday.isEmpty {
                        Section("Heute nicht dran") {
                            ForEach(notDueToday) { supplement in
                                PausedRow(supplement: supplement,
                                          onDelete: { delete(supplement) })
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
    }

    /// Supplements, die laut Intervall heute dran sind.
    private var dueToday: [Supplement] {
        supplements.filter { $0.isDue(on: .now) }
    }

    /// Supplements, die heute Pause haben.
    private var notDueToday: [Supplement] {
        supplements.filter { !$0.isDue(on: .now) }
    }

    private var trimmedName: String {
        newName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Hinzufügen geht nur mit Namen und mindestens einer Tageszeit.
    private var canAdd: Bool {
        !trimmedName.isEmpty && (newMorning || newNoon || newEvening)
    }

    private func addSupplement() {
        guard canAdd else { return }
        modelContext.insert(Supplement(name: trimmedName,
                                       takesMorning: newMorning,
                                       takesNoon: newNoon,
                                       takesEvening: newEvening,
                                       intervalDays: newInterval))
        newName = ""
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
