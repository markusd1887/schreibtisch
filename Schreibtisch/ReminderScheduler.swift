import Foundation
import UserNotifications

/// Kümmert sich um die macOS-Mitteilungen für Notizen.
///
/// `UNUserNotificationCenter` ist die "Mitteilungszentrale" des Systems.
/// Dort melden wir an, *was* angezeigt werden soll (Inhalt) und *wann* (Trigger).
enum ReminderScheduler {
    private static var center: UNUserNotificationCenter { .current() }

    /// Fragt einmalig um Erlaubnis, Mitteilungen anzeigen zu dürfen.
    /// macOS zeigt dazu beim ersten Mal einen Dialog; danach merkt es sich die Antwort.
    static func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Mitteilungs-Erlaubnis fehlgeschlagen: \(error)")
            }
        }
    }

    /// Plant (oder ersetzt) die Mitteilung einer Notiz.
    /// Ohne Erinnerung oder mit einem Zeitpunkt in der Vergangenheit wird nur aufgeräumt.
    static func update(for note: Note) {
        cancel(for: note)

        guard let date = note.reminderDate, date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = note.body.isEmpty ? "Erinnerung" : note.body
        content.sound = .default

        // Der Trigger ist der Auslöser: hier ein fester Kalender-Zeitpunkt.
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Gleiche ID wie vorher -> eine eventuell alte Mitteilung wird ersetzt.
        let request = UNNotificationRequest(
            identifier: note.notificationID, content: content, trigger: trigger
        )
        center.add(request) { error in
            if let error {
                print("Mitteilung konnte nicht geplant werden: \(error)")
            }
        }
    }

    /// Entfernt die geplante (und ggf. schon angezeigte) Mitteilung einer Notiz.
    static func cancel(for note: Note) {
        center.removePendingNotificationRequests(withIdentifiers: [note.notificationID])
        center.removeDeliveredNotifications(withIdentifiers: [note.notificationID])
    }
}

/// Sorgt dafür, dass Mitteilungen auch dann als Banner erscheinen,
/// wenn die App gerade im Vordergrund ist. (Ohne das würde macOS sie dann verschlucken.)
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
