import Foundation

extension SyncDestination {
    init(_ d: Destination) {
        self.init(origin: d.originCode, destination: d.destinationCode, month: d.month,
                  includeNearby: d.includeNearby, threshold: d.threshold, currency: d.currency)
    }
}

@MainActor
final class SyncService {
    static let shared = SyncService()

    private let maxDestinations = 10
    private let tokenKey = "pushToken"
    private let syncedKey = "hasSyncedToServer"

    private var pushToken: String? = UserDefaults.standard.string(forKey: "pushToken")

    private var destinations: [SyncDestination]?
    private var pendingTask: Task<Void, Never>?

    private var environment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    func updateDestinations(_ list: [SyncDestination]) {
        destinations = Array(list.prefix(maxDestinations))
        if destinations?.isEmpty == true && !UserDefaults.standard.bool(forKey: syncedKey) { return }
        scheduleSync()
    }

    func cancelPending() {
        pendingTask?.cancel()
        pendingTask = nil
    }

    func reset() {
        cancelPending()
        pushToken = nil
        destinations = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: syncedKey)
    }

    func setPushToken(_ token: String) {
        guard token != pushToken else { return }
        pushToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
        scheduleSync()
    }

    private func scheduleSync() {
        pendingTask?.cancel()
        pendingTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, let destinations else { return }
            let request = SyncRequest(installId: InstallID.value, pushToken: pushToken,
                                      environment: environment, locale: Format.languageCode,
                                      destinations: destinations)
            do {
                try await APIClient.shared.syncSubscriptions(request)
                UserDefaults.standard.set(true, forKey: syncedKey)
            } catch {
                #if DEBUG
                if !Task.isCancelled { print("Синхронизация не удалась: \(error.localizedDescription)") }
                #endif
            }
        }
    }
}
