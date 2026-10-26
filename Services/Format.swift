//
//  Format.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation


enum Format {
    // Язык интерфейса, который iOS выбрала для приложения: "ru" или "en".
    // Русский у русскоязычных пользователей, английский у всех остальных.
    static var languageCode: String {
        (Bundle.main.preferredLocalizations.first ?? "ru").hasPrefix("ru") ? "ru" : "en"
    }

    static var isRussian: Bool { languageCode == "ru" }

    // Формат чисел и дат подстраивается под язык: "66 254 ₸" и "66,254 ₸"
    static var locale: Locale { Locale(identifier: isRussian ? "ru_RU" : "en_US") }
    
    // Знак валюты: ₸, ₽, $, €... Для валют без привычного знака показываем код (UZS, KGS...)
    static func symbol(for currency: String) -> String {
        switch currency.lowercased() {
        case "kzt": return "₸"
        case "rub": return "₽"
        case "usd": return "$"
        case "eur": return "€"
        case "gbp": return "£"
        case "uah": return "₴"
        case "try": return "₺"
        case "azn": return "₼"
        case "gel": return "₾"
        case "amd": return "֏"
        case "pln": return "zł"
        case "czk": return "Kč"
        case "huf": return "Ft"
        default:    return currency.uppercased()
        }
    }

    // 66254, "kzt" → "66 254 ₸"; 156, "usd" → "156 $" (по-английски "$156")
    static func price(_ value: Int, currency: String = "kzt") -> String {
        let number = value.formatted(.number.locale(locale))
        let symbol = symbol(for: currency)
        if !isRussian, ["usd", "eur", "gbp"].contains(currency.lowercased()) {
            return "\(symbol)\(number)"
        }
        return "\(number)\u{00A0}\(symbol)"   // неразрывный пробел: знак не отрывается от числа
    }
    
    static func month(_ yyyyMM: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM"
        guard let date = parser.date(from: yyyyMM) else { return yyyyMM }
        let out = DateFormatter()
        out.locale = locale
        out.dateFormat = "LLLL yyyy"
        return out.string(from: date).capitalized
    }

    // "2026-11-16" → "16 нояб." или "Nov 16"
    static func day(_ yyyyMMdd: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: yyyyMMdd) else { return yyyyMMdd }
        let out = DateFormatter()
        out.locale = locale
        out.setLocalizedDateFormatFromTemplate("dMMM")
        return out.string(from: date)
    }
    
}
