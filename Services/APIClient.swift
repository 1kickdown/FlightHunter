//
//  APIClient.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation

enum APIError: LocalizedError{
    case badURL
    case server(Int)
    case network

    var errorDescription: String?{
        switch self{
        case .badURL:
            return String(localized: "Неверный адрес запроса")
        case .server(let status):
            return status >= 500
                ? String(localized: "Сервер временно недоступен. Попробуйте позже.")
                : String(localized: "Ошибка запроса (код \(status))")
        case .network:
            return String(localized: "Не удалось связаться с сервером. Проверьте интернет.")
        }
    }
}

struct APIClient {
    static let shared = APIClient()

    private let baseURL = "https://plrdhdldubkfveljlvks.supabase.co/functions/v1"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    func fetchPrices(origin: String, destination: String, month: String, nearby: Bool = false,
                     currency: String = "kzt") async throws -> PricesResponse {
        var query = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "month", value: month),
            URLQueryItem(name: "currency", value: currency)
        ]

        if nearby { query.append(URLQueryItem(name: "nearby", value: "true")) }
        return try await get("prices", query: query)
    }

    func fetchCities() async throws -> [City] {
        let response: CitiesResponse = try await get("cities", query: [])
        return response.cities
    }

    func fetchBuyLink(origin: String, destination: String,
                      date: String, returnDate: String?) async throws -> URL {
        var query = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "date", value: date)
        ]
        if let returnDate { query.append(URLQueryItem(name: "return_date", value: returnDate)) }
        let response: BuyLinkResponse = try await get("buy-link", query: query)
        guard let url = URL(string: response.url) else { throw APIError.badURL }
        return url
    }

    func syncSubscriptions(_ request: SyncRequest) async throws {
        let _: SyncResponse = try await post("sync", body: request)
    }

    func deleteDeviceData(installId: String) async throws {
        let _: OKResponse = try await post("delete-device", body: DeleteDeviceRequest(installId: installId))
    }

    private func get<T: Decodable>(_ function: String, query: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)/\(function)") else {
            throw APIError.badURL
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw APIError.badURL }
        return try await send(URLRequest(url: url))
    }

    private func post<Body: Encodable, T: Decodable>(_ function: String, body: Body) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(function)") else { throw APIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw APIError.server(http.statusCode)
            }
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network
        }
    }
}

struct BuyLinkResponse: Codable {
    let url: String
}

struct SyncDestination: Codable, Equatable {
    let origin: String
    let destination: String
    let month: String
    let includeNearby: Bool
    let threshold: Int?
    let currency: String
}

struct SyncRequest: Encodable {
    let installId: String
    let pushToken: String?
    let environment: String
    let locale: String
    let destinations: [SyncDestination]
}

struct SyncResponse: Decodable {
    let ok: Bool
    let count: Int
}

struct DeleteDeviceRequest: Encodable {
    let installId: String
}

struct OKResponse: Decodable {
    let ok: Bool
}
