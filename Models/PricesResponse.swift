//
//  PricesResponse.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation


struct Day: Codable, Identifiable, Hashable{
    let date: String
    let price: Int
    let transfers: Int
    let returnDate: String?
    let origin: String
    let destination: String
    
    var id: String { "\(date)|\(returnDate ?? "")|\(origin)|\(destination)" }
}



struct PricesResponse: Codable{
    let origin: String
    let destination: String
    let month: String
    let nearby: Bool
    let currency: String
    let days: [Day]
    let cheapest: [Day]
    let noFreshPrices: Bool
    let cached: Bool
    let stale: Bool?
}

