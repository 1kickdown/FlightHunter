//
//  AppLinks.swift
//  FlightHunter
//
//  Публичные ссылки приложения. Пока поле пустое, соответствующая строка на экране
//  «О приложении» не показывается (чтобы не было битых ссылок).
//

import Foundation

enum AppLinks {
    // Адрес страницы политики конфиденциальности (появится после публикации сайта)
    static let privacyPolicy = "https://1kickdown.github.io/flighthunter-site/privacy.html"
    // Контактный email поддержки
    static let supportEmail = "idaniyar363@gmail.com"

    static var privacyPolicyURL: URL? {
        privacyPolicy.isEmpty ? nil : URL(string: privacyPolicy)
    }

    static var supportURL: URL? {
        supportEmail.isEmpty ? nil : URL(string: "mailto:\(supportEmail)")
    }
}
