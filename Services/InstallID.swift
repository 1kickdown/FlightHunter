//
//  InstallID.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import Foundation

enum InstallID {
    private static let key = "installID"
    
    static var value: String {
        if let saved = UserDefaults.standard.string(forKey: key){
            return saved
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
