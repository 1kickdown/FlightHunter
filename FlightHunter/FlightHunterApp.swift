import SwiftUI
import SwiftData

// Точка входа приложения: отсюда iOS запускает первый экран.
@main
struct FlightHunterApp: App {
    // Подключаем AppDelegate: через него iOS присылает push-токен и нажатия на уведомления
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            DestinationListView()
        }
        .modelContainer(for: Destination.self)
    }
}
