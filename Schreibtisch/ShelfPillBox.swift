import SwiftUI
import SwiftData

/// Die kleine Pillendose auf dem Wandregal.
///
/// Vorne hat sie drei Fächer: morgens, mittags, abends.
/// - Liegt noch eine Pille im Fach, ist zu dieser Tageszeit etwas offen.
/// - Ein Haken heißt: alles genommen.
/// - Ein leeres Fach: Zu dieser Tageszeit ist heute nichts geplant.
///
/// Solange heute noch etwas offen ist, zeigt ein Bordeaux-Kreis die Anzahl.
/// Ein Klick öffnet die ganze Tablettenbox zum Abhaken und Bearbeiten.
struct ShelfPillBox: View {
    @Query private var supplements: [Supplement]
    /// Alle Einnahmen – damit sich die Dose sofort ändert, wenn etwas abgehakt wird.
    @Query private var intakes: [SupplementIntake]

    @State private var isOpen = false

    /// Zustand eines Fachs.
    private enum Slot {
        case nothingPlanned
        case done
        case open(Int)
    }

    var body: some View {
        // Jede Minute neu zeichnen, damit nach Mitternacht "heute" stimmt.
        TimelineView(.everyMinute) { _ in
            let slots = DayTime.allCases.map { status(for: $0) }
            let openCount = slots.reduce(0) { sum, slot in
                if case .open(let n) = slot { return sum + n }
                return sum
            }

            Button {
                isOpen = true
            } label: {
                box(slots: slots)
                    .overlay(alignment: .topTrailing) {
                        if openCount > 0 {
                            Text("\(openCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .frame(minWidth: 17, minHeight: 17)
                                .background(Circle().fill(Color.bordeaux))
                                .overlay(Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1))
                                .offset(x: 7, y: -7)
                        }
                    }
            }
            .buttonStyle(.plain)
            .help(openCount > 0 ? "Tablettenbox: heute noch \(openCount) offen – klicken zum Öffnen"
                                : "Tablettenbox – klicken zum Öffnen")
            .accessibilityLabel(openCount > 0 ? "Tablettenbox, heute noch \(openCount) offen"
                                              : "Tablettenbox, alles erledigt")
        }
        // Das große Fenster mit der bisherigen Tablettenbox
        .sheet(isPresented: $isOpen) {
            VStack(spacing: 14) {
                SupplementTrackerView()
                Button("Fertig") { isOpen = false }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(22)
            .frame(width: 330)
            .background(DeskBackground())
        }
    }

    /// Die Dose selbst: Messing, mit Deckelkante und drei Fächern.
    private func box(slots: [Slot]) -> some View {
        VStack(spacing: 4) {
            // Deckelkante
            Rectangle()
                .fill(Color.brassDark.opacity(0.7))
                .frame(height: 2)
                .padding(.horizontal, 2)

            HStack(spacing: 4) {
                ForEach(slots.indices, id: \.self) { i in
                    compartment(slots[i])
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 7)
        .padding(.bottom, 6)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [.brass, .brassDark], startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.35), radius: 2, y: 2)
        }
        .contentShape(Rectangle())
    }

    /// Ein Fach: dunkle Vertiefung, darin Pille, Haken oder nichts.
    private func compartment(_ slot: Slot) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.leatherDark.opacity(0.85))
            .frame(width: 16, height: 20)
            .overlay {
                switch slot {
                case .nothingPlanned:
                    EmptyView()
                case .done:
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.notepadPaper)
                case .open:
                    // Eine Kapsel: halb Elfenbein, halb Koralle
                    Capsule()
                        .fill(LinearGradient(stops: [
                            .init(color: Color.notepadPaper, location: 0.5),
                            .init(color: Color(red: 0.88, green: 0.45, blue: 0.35), location: 0.5)
                        ], startPoint: .top, endPoint: .bottom))
                        .frame(width: 6, height: 13)
                        .rotationEffect(.degrees(25))
                }
            }
    }

    /// Wie viele Supplements sind zu dieser Tageszeit heute noch offen?
    private func status(for time: DayTime) -> Slot {
        let calendar = Calendar.current
        let planned = supplements.filter { $0.isDue(on: .now) && $0.isScheduled(at: time) }
        guard !planned.isEmpty else { return .nothingPlanned }

        let takenToday = intakes.filter {
            calendar.isDateInToday($0.day) && $0.timeRaw == time.rawValue
        }
        let open = planned.filter { supplement in
            !takenToday.contains { $0.supplement?.persistentModelID == supplement.persistentModelID }
        }.count
        return open == 0 ? .done : .open(open)
    }
}

#Preview {
    ShelfPillBox()
        .modelContainer(for: [Supplement.self, SupplementIntake.self], inMemory: true)
        .padding(40)
}
