//
//  Format+Calendar.swift
//  FlightHunter
//
//  Created by kickdown on 08.10.2026.
//

import Foundation


extension Format {
    private static let monthParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f
    }()
    
    
    static func currentMonth() -> String {
        monthParser.string(from: Date())
    }
    
    static func shiftMonth(_ month: String, by n: Int) -> String? {
        guard let date = monthParser.date(from: month ), let shifted = Calendar.current.date(byAdding: .month, value: n, to: date)
                else {
            return nil
        }
        return monthParser.string(from: shifted)
    }
    
    static func monthLayout(_ month: String) -> (leadingBlanks: Int, dayCount: Int)? {
        let calendar = Calendar(identifier: .gregorian)
        guard let first = monthParser.date(from: month), let range = calendar.range(of: .day, in: .month, for: first)
                else { return nil}
        let weekday = calendar.component(.weekday, from: first)
        return ((weekday + 5) % 7, range.count)
    }
    
    // 66254 → "66к" (по-английски "66k")
    static func shortPrice(_ value: Int) -> String {
        guard value >= 1000 else { return "\(value)" }
        return String(localized: "\(Int((Double(value) / 1000).rounded()))к")
    }

    // Подписи дней недели, начиная с понедельника: ["Пн", "Вт", ...] или ["Mon", "Tue", ...]
    static func weekdayHeaders() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? []   // начинается с воскресенья
        guard symbols.count == 7 else { return ["1", "2", "3", "4", "5", "6", "7"] }
        return (Array(symbols[1...]) + [symbols[0]]).map { $0.capitalized }
    }
}
