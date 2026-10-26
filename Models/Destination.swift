//
//  Destination.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation
import SwiftData


@Model

final class Destination{
    var originCode: String
    var originName: String
    var destinationCode: String
    var destinationName: String
    var originNameEn: String?        // английские названия (у старых направлений дозаполняются позже)
    var destinationNameEn: String?
    var month: String
    // Порог цены в валюте направления. Раньше поле называлось thresholdKZT (originalName сохраняет старые данные)
    @Attribute(originalName: "thresholdKZT") var threshold: Int?
    var currency: String = "kzt"      // валюта направления: kzt, rub, usd...
    var includeNearby: Bool
    var createdAt: Date
    
    init (originCode: String, originName: String, destinationCode: String, destinationName: String, month: String, threshold: Int? = nil, includeNearby: Bool = false,
          originNameEn: String? = nil, destinationNameEn: String? = nil, currency: String = "kzt"){
        self.originCode = originCode
        self.originName = originName
        self.destinationCode = destinationCode
        self.destinationName = destinationName
        self.originNameEn = originNameEn
        self.destinationNameEn = destinationNameEn
        self.month = month
        self.threshold = threshold
        self.currency = currency
        self.includeNearby = includeNearby
        self.createdAt = Date()
    }
    
    // Названия на языке интерфейса; если английского названия нет, показываем русское
    var displayOriginName: String { Format.isRussian ? originName : (originNameEn ?? originName) }
    var displayDestinationName: String { Format.isRussian ? destinationName : (destinationNameEn ?? destinationName) }

    var title: String { "\(displayOriginName) → \(displayDestinationName)" }
}


/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


