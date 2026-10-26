//
//  WidgetSnapshot.swift
//  FlightHunter
//
//  Created by kickdown on 20.10.2026.
//

import Foundation
import WidgetKit

struct WidgetDestination: Codable, Identifiable, Hashable {
    let title: String
    let originCode: String
    let destinationCode: String
    let month: String
    let includeNearby: Bool
    let threshold: Int?          // порог в валюте направления
    let currency: String         // валюта направления
    var bestPrice: Int?
    var bestDate: String?
    
    var id: String { "\(originCode)-\(destinationCode)-\(month)-\(includeNearby)-\(currency)" }
    
    var isBelowThreshold: Bool {
        guard let price = bestPrice, let threshold = threshold else { return false }
        return price <= threshold
    }
}


struct WidgetSnapshot: Codable {
    var destinations: [WidgetDestination]
    var updatedAt: Date
}

enum SharedStore {
    static let groupID = "group.com.kickdown.FlightHunter"
    private static let key = "widgetSnapshot"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: groupID ) }
    
    static func save(_ snapshot: WidgetSnapshot, reloadWidgets: Bool = true) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
        if reloadWidgets { WidgetCenter.shared.reloadAllTimelines() }
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
