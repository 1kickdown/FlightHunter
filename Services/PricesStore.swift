//
//  PricesStore.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation
import Observation

enum  PriceState {
    case loading
    case loaded(PricesResponse)
    case failed(String)
}

@MainActor
@Observable
final class PricesStore {
    private(set) var states: [String: PriceState] = [:]
    private(set) var version = 0

    // Ключ запроса: одно направление + месяц + режим «соседние города»
    private func key(for d: Destination) -> String {
        "\(d.originCode)-\(d.destinationCode)-\(d.month)-\(d.includeNearby)-\(d.currency)"
    }

    func state(for d: Destination) -> PriceState {
        states[key(for: d)] ?? .loading
    }

    // Загружает цены. force = true — принудительно обновить (pull-to-refresh).
    func load(_ d: Destination, force: Bool = false) async {
        let k = key(for: d)
        // Уже загружено и обновлять не просят — ничего не делаем
        if !force, let s = states[k], case .loaded = s { return }
        if states[k] == nil { states[k] = .loading }

        do {
            let response = try await APIClient.shared.fetchPrices(
                origin: d.originCode, destination: d.destinationCode,
                month: d.month, nearby: d.includeNearby, currency: d.currency)
            states[k] = .loaded(response)
            version += 1
        } catch {
            states[k] = .failed(error.localizedDescription)
            version += 1
        }
    }
}
