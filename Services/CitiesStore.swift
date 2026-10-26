//
//  CitiesStore.swift
//  FlightHunter
//
//  Created by kickdown on 08.10.2026.
//

import Foundation
import Observation

enum CitiesState {
    case idle
    case loading
    case loaded([City])
    case failed(String)
}


@MainActor
@Observable

final class CitiesStore {
    static let shared = CitiesStore()
    private(set) var state: CitiesState = .idle
    
    func load() async {
        switch state{
        case .loaded, .loading: return
        case .idle, .failed: break
        }
        state = .loading
        do {
            state = .loaded(try await APIClient.shared.fetchCities())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
