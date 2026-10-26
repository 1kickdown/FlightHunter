//
//  APIClient.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation


enum APIError: LocalizedError{
    case badURL
    case server(Int)          // код ответа сервера
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

    // Адрес нашего облачного бэкенда (Supabase). Работает и в симуляторе, и на реальном iPhone.
    // Чтобы временно проверить локальный бэкенд на симуляторе, замените на
    // "http://127.0.0.1:54321/functions/v1" (и запустите `supabase start` + `functions serve`).
    // Для обычного http iOS потребует временно добавить в Info.plist ключ
    // NSAppTransportSecurity → NSAllowsLocalNetworking = YES (в релизе его быть не должно).
    private let baseURL = "https://plrdhdldubkfveljlvks.supabase.co/functions/v1"


    // Превращает JSON в наши модели: return_date → returnDate
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // Обратное преобразование для запросов: includeNearby → include_nearby
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

    // Партнёрская ссылка на поиск билетов в Aviasales для конкретной даты.
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

    // Отправляет на сервер ID установки, push-токен и список направлений.
    // Сервер хранит их, чтобы по расписанию проверять цены и присылать пуши.
    func syncSubscriptions(_ request: SyncRequest) async throws {
        let _: SyncResponse = try await post("sync", body: request)
    }

    // Удаляет с сервера все данные этого устройства (ID установки, push-токен, направления).
    func deleteDeviceData(installId: String) async throws {
        let _: OKResponse = try await post("delete-device", body: DeleteDeviceRequest(installId: installId))
    }

    // MARK: - Общие методы

    // GET-запрос к функции бэкенда.
    private func get<T: Decodable>(_ function: String, query: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)/\(function)") else {
            throw APIError.badURL
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw APIError.badURL }
        return try await send(URLRequest(url: url))
    }

    // POST-запрос с JSON-телом.
    private func post<Body: Encodable, T: Decodable>(_ function: String, body: Body) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(function)") else { throw APIError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return try await send(request)
    }

    // Выполняет запрос, проверяет ответ, разбирает JSON.
    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                // Текст ошибки показываем сами, на языке интерфейса (тексты сервера на русском)
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


// Ответ функции "buy-link".
struct BuyLinkResponse: Codable {
    let url: String
}

// Одно направление в запросе синхронизации (поля совпадают с тем, что ждёт функция "sync").
struct SyncDestination: Codable, Equatable {
    let origin: String
    let destination: String
    let month: String
    let includeNearby: Bool
    let threshold: Int?         // порог в валюте направления
    let currency: String
}

// Тело запроса синхронизации.
struct SyncRequest: Encodable {
    let installId: String
    let pushToken: String?     // nil — токена пока нет
    let environment: String    // "sandbox" (сборка из Xcode) или "production"
    let locale: String         // язык интерфейса ("ru" или "en"): на нём сервер напишет текст пуша
    let destinations: [SyncDestination]
}

// Ответ функции "sync".
struct SyncResponse: Decodable {
    let ok: Bool
    let count: Int
}

// Тело запроса удаления данных устройства.
struct DeleteDeviceRequest: Encodable {
    let installId: String
}

// Простой ответ «всё в порядке».
struct OKResponse: Decodable {
    let ok: Bool
}
