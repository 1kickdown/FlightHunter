//
//  Currency.swift
//  FlightHunter
//
//  Список валют, которые можно выбрать для направления, и выбор валюты по умолчанию.
//  Валюты должны совпадать со списком на сервере (backend/supabase/functions/_shared/currencies.ts).
//

import Foundation

enum Currencies {
    // Коды в нижнем регистре, как их понимает сервер
    static let all = ["kzt", "rub", "usd", "eur", "uzs", "kgs", "tjs", "azn", "gel",
                      "amd", "byn", "uah", "try", "gbp", "pln", "czk", "huf", "aed"]

    private static let lastChoiceKey = "lastCurrency"

    // Название валюты на языке интерфейса: «Казахстанский тенге» / "Kazakhstani Tenge"
    static func name(_ code: String) -> String {
        Format.locale.localizedString(forCurrencyCode: code.uppercased()) ?? code.uppercased()
    }

    // Валюта, выбранная в форме по умолчанию: последняя использованная,
    // а при первом запуске — по региону устройства.
    static var initialChoice: String {
        if let saved = UserDefaults.standard.string(forKey: lastChoiceKey), all.contains(saved) {
            return saved
        }
        return regionDefault
    }

    static func remember(_ code: String) {
        UserDefaults.standard.set(code, forKey: lastChoiceKey)
    }

    private static var regionDefault: String {
        let region = Locale.current.region?.identifier ?? ""
        let byRegion = ["KZ": "kzt", "RU": "rub", "UZ": "uzs", "KG": "kgs", "TJ": "tjs", "AZ": "azn",
                        "GE": "gel", "AM": "amd", "BY": "byn", "UA": "uah", "TR": "try", "GB": "gbp",
                        "PL": "pln", "CZ": "czk", "HU": "huf", "AE": "aed", "US": "usd"]
        if let code = byRegion[region] { return code }
        let euroRegions: Set<String> = ["DE", "FR", "IT", "ES", "AT", "NL", "BE", "PT", "GR", "FI", "IE",
                                        "SK", "SI", "EE", "LV", "LT", "LU", "MT", "CY", "HR"]
        if euroRegions.contains(region) { return "eur" }
        // Регион неизвестен: русскоязычным — тенге (основная аудитория), остальным — доллары
        return Format.isRussian ? "kzt" : "usd"
    }
}
