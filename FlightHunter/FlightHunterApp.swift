import SwiftUI
import SwiftData

@main
struct FlightHunterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            DestinationListView()
        }
        .modelContainer(for: Destination.self)
    }
}
