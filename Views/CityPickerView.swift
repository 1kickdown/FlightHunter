//
//  CityPickerView.swift
//  FlightHunter
//
//  Created by kickdown on 08.10.2026.
//

import SwiftUI

struct CityPickerView: View {
    let title: LocalizedStringKey
    let cities: [City]
    
    @Binding var selection: City?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    
    
    private let popularCodes = ["KGF", "ALA", "NQZ", "BUD", "VIE", "PRG", "WAW",
                                "IST", "BER", "PAR", "ROM", "MOW"]
    
    private var popular: [City] {
        popularCodes.compactMap { code in cities.first { $0.code == code } }
    }
    
    private var results: [City] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        
        let found = cities.filter {
            $0.name.lowercased().contains(q) ||
            $0.nameEn.lowercased().contains(q) ||
            $0.code.lowercased() == q
        }
        return Array(found.prefix(50))
    }
    
    
    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                Section("Популярные") {
                    ForEach(popular) { row($0) }
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(results) { row($0) }
            }
        }
        .scrollContentBackground(.hidden)
        .background { ThemeBackground() }
        .searchable(text: $query, prompt: "Город или код")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func row (_ city: City) -> some View {
        Button {
            selection = city
            dismiss()
        } label: {
            HStack {
                Text(city.displayName)
                Spacer()
                Text(city.code).foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
        }
    }
}

//#Preview {
//    CityPickerView()
//}
