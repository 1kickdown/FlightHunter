//
//  SyncService.swift
//  FlightHunter
//
//  Передаёт на сервер список направлений и push-токен, чтобы сервер проверял цены
//  и присылал пуши, даже когда приложение закрыто.
//

import Foundation

// Преобразование сохранённого направления в формат запроса синхронизации.
extension SyncDestination {
    init(_ d: Destination) {
        self.init(origin: d.originCode, destination: d.destinationCode, month: d.month,
                  includeNearby: d.includeNearby, threshold: d.threshold, currency: d.currency)
    }
}

@MainActor
final class SyncService {
    static let shared = SyncService()

    // Сервер принимает не больше 10 направлений на устройство
    private let maxDestinations = 10
    private let tokenKey = "pushToken"
    private let syncedKey = "hasSyncedToServer"

    // Последний известный push-токен. Хранится на устройстве, чтобы при запуске приложения
    // синхронизация не затёрла токен на сервере раньше, чем iOS выдаст его заново.
    private var pushToken: String? = UserDefaults.standard.string(forKey: "pushToken")

    // Последний список направлений; nil, пока экран списка ещё ничего не передал
    private var destinations: [SyncDestination]?
    private var pendingTask: Task<Void, Never>?

    // Тестовая сборка из Xcode использует «песочницу» APNs, App Store и TestFlight — боевой сервер
    private var environment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    // Вызывается, когда изменился список направлений.
    func updateDestinations(_ list: [SyncDestination]) {
        destinations = Array(list.prefix(maxDestinations))
        // Если направлений нет и на сервер мы ещё ничего не отправляли — сервер трогать незачем
        if destinations?.isEmpty == true && !UserDefaults.standard.bool(forKey: syncedKey) { return }
        scheduleSync()
    }

    // Отменяет запланированную, но ещё не отправленную синхронизацию.
    func cancelPending() {
        pendingTask?.cancel()
        pendingTask = nil
    }

    // Забывает всё, что связано с сервером (после удаления данных пользователя).
    func reset() {
        cancelPending()
        pushToken = nil
        destinations = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: syncedKey)
    }

    // Вызывается, когда iOS выдала push-токен устройства.
    func setPushToken(_ token: String) {
        guard token != pushToken else { return }
        pushToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
        scheduleSync()
    }

    // Отправляет данные через секунду после последнего изменения: несколько быстрых правок
    // превращаются в один запрос. Если запрос не удался, данные уйдут при следующем изменении
    // или при следующем запуске приложения.
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
