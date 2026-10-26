//
//  PriceCalendarView.swift
//  FlightHunter
//
//  Created by kickdown on 08.10.2026.
//

import SwiftUI

// Календарная сетка месяца: в каждой клетке число и самая низкая цена на эту дату.
// Нажатие на клетку с ценой открывает поиск билетов на эту дату (onSelect).
struct PriceCalendarView: View {
    let month: String          // "2026-11"
    let days: [Day]            // цены из ответа бэкенда
    let threshold: Int?        // порог пользователя; nil, если не задан
    let onSelect: (Day) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = Format.weekdayHeaders()

    // Самый дешёвый вариант на каждую дату: ["2026-11-16": Day, ...]
    private var bestDayByDate: [String: Day] {
        Dictionary(days.map { ($0.date, $0) },
                   uniquingKeysWith: { $0.price <= $1.price ? $0 : $1 })
    }

    private var priceByDate: [String: Int] { bestDayByDate.mapValues(\.price) }
    private var lowestPrice: Int? { priceByDate.values.min() }

    // Дёшево: ниже порога пользователя, а если порога нет — нижняя четверть цен месяца
    private func isCheap(_ price: Int) -> Bool {
        if let threshold { return price <= threshold }
        let sorted = priceByDate.values.sorted()
        guard !sorted.isEmpty else { return false }
        return price <= sorted[(sorted.count - 1) / 4]
    }

    var body: some View {
        VStack(spacing: 6) {
            // Подписи дней недели
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) {
                    Text($0).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            if let layout = Format.monthLayout(month) {
                LazyVGrid(columns: columns, spacing: 4) {
                    // Одна общая нумерация клеток: сначала пустые (до 1-го числа), затем дни месяца
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

    // Клетка дня: если на эту дату есть цена, она нажимается
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

        // Самый дешёвый день месяца залит синим с белым текстом, «выгодные» дни — светло-зелёные,
        // остальные с ценой — нейтральные, дни без цены — только число
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
                Text(" ").font(.caption)   // сохраняем высоту клетки
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill))
    }
}
