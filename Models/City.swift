//
//  City.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation


struct City: Codable, Identifiable, Hashable{
    let code: String
    let name: String
    let nameEn: String
    let country: String
    
    var id: String { code }

    // Название на языке интерфейса
    var displayName: String { Format.isRussian ? name : nameEn }
}


struct CitiesResponse: Codable{
    let cities: [City]
}

