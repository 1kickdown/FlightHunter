//
//  PriceCalendarView.swift
//  FlightHunter
//
//  Created by kickdown on 08.10.2026.
//

import SwiftUI

struct PriceCalendarView: View {
    let month: String
    let days: [Day]
    let threshold: Int?
    let onSelect: (Day) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = Format.weekdayHeaders()

    private var bestDayByDate: [String: Day] {
        Dictionary(days.map { ($0.date, $0) },
                   uniquingKeysWith: { $0.price <= $1.price ? $0 : $1 })
    }

    private var priceByDate: [String: Int] { bestDayByDate.mapValues(\.price) }
    private var lowestPrice: Int? { priceByDate.values.min() }

    private func isCheap(_ price: Int) -> Bool {
        if let threshold { return price <= threshold }
        let sorted = priceByDate.values.sorted()
        guard !sorted.isEmpty else { return false }
        return price <= sorted[(sorted.count - 1) / 4]
    }

    var body: some View {
        VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) {
                    Text($0).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            if let layout = Format.monthLayout(month) {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(0..<(layout.leadingBlanks + layout.dayCount), id: \.self) { index in
                        let day = index - layout.leadingBlanks + 1
                        if day >= 1 {
                            cell(day)
                        } else {
                            Color.clear.frame(height: 46)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ day: Int) -> some View {
        let key = "\(month)-" + String(format: "%02d", day)
        if let best = bestDayByDate[key] {
            Button { onSelect(best) } label: { cellBody(day, price: best.price) }
                .buttonStyle(.plain)
        } else {
            cellBody(day, price: nil)
        }
    }

    private func cellBody(_ day: Int, price: Int?) -> some View {
        let cheap = price.map(isCheap) ?? false
        let isLowest = price != nil && price == lowestPrice

        let fill: Color = isLowest ? Theme.brandLight
            : cheap ? Theme.good.opacity(0.16)
            : price != nil ? Color.primary.opacity(0.06) : .clear

        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption2)
                .foregroundStyle(isLowest ? Color.white.opacity(0.9) : (price == nil ? Color.secondary.opacity(0.6) : Color.secondary))
            if let price {
                Text(Format.shortPrice(price))
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(isLowest ? Color.white : (cheap ? Theme.good : Color.primary))
            } else {
                Text(" ").font(.caption)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill))
    }
}
