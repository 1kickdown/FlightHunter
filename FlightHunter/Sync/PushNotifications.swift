//
//  PushNotifications.swift
//  FlightHunter
//
//  Всё про пуш-уведомления: запрос разрешения, получение токена устройства,
//  показ пуша в открытом приложении и переход на нужный экран по нажатию.
//

import UIKit
import UserNotifications
import Observation

// Куда вести пользователя по нажатию на пуш (данные приходят в самом пуше от сервера).
struct PushRoute: Equatable {
    let origin: String
    let destination: String
    let month: String
    let nearby: Bool
}

// Хранит «отложенный переход»: AppDelegate записывает сюда маршрут, а экран списка его открывает.
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()
    var pendingRoute: PushRoute?
}

// Запрос разрешения на уведомления и регистрация в Apple Push (APNs).
@MainActor
enum PushPermission {
    // Спрашивает разрешение, если ещё не спрашивали; если оно уже есть — просто регистрирует устройство.
    // Вызываем в осмысленный момент (когда пользователь добавил направление), а не при запуске.
    static func requestIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted { UIApplication.shared.registerForRemoteNotifications() }
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        default:
            break   // пользователь запретил уведомления — не настаиваем
        }
    }

    // При запуске: если разрешение уже выдано, обновляем токен (он может меняться), но ничего не спрашиваем.
    static func registerIfAuthorized() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        default:
            break
        }
    }
}

// Делегат приложения: iOS сообщает ему о push-токене и о нажатиях на уведомления.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in await PushPermission.registerIfAuthorized() }
        return true
    }

    // iOS выдала токен устройства: переводим в строку из hex-символов и отправляем на сервер
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in SyncService.shared.setPushToken(token) }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Пока у аккаунта нет Apple Developer Program, здесь будет ошибка — это ожидаемо
        #if DEBUG
        print("Не удалось зарегистрироваться для пушей: \(error.localizedDescription)")
        #endif
    }

    // Пуш пришёл, когда приложение открыто: всё равно показываем баннер
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Пользователь нажал на пуш: запоминаем, какое направление открыть
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let origin = info["origin"] as? String,
              let destination = info["destination"] as? String,
              let month = info["month"] as? String else { return }
        let nearby = (info["nearby"] as? Bool) ?? false
        await MainActor.run {
            AppRouter.shared.pendingRoute = PushRoute(origin: origin, destination: destination,
                                                      month: month, nearby: nearby)
        }
    }
}
