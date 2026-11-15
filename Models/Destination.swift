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
    var originNameEn: String?
    var destinationNameEn: String?
    var month: String
    @Attribute(originalName: "thresholdKZT") var threshold: Int?
    var currency: String = "kzt"
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
    
    var displayOriginName: String { Format.isRussian ? originName : (originNameEn ?? originName) }
    var displayDestinationName: String { Format.isRussian ? destinationName : (destinationNameEn ?? destinationName) }

    var title: String { "\(displayOriginName) → \(displayDestinationName)" }
}
