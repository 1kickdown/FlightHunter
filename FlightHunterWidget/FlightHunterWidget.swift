//
//  FlightHunterWidget.swift
//  FlightHunterWidget
//
//  Created by kickdown on 20.10.2026.
//

import WidgetKit
import SwiftUI
import UIKit

struct PriceEntry: TimelineEntry {
    let date: Date
    let destinations: [WidgetDestination]
    
    // Направление с самой низкой ценой. Цены в разных валютах сравнивать нельзя (курсов у нас нет),
    // поэтому берём валюту самого нового направления с ценой и ищем минимум среди направлений в ней.
    var best: WidgetDestination? {
        let priced = destinations.filter { $0.bestPrice != nil }
        guard let currency = priced.first?.currency else { return nil }
        return priced
            .filter { $0.currency == currency }
            .min { ($0.bestPrice ?? .max) < ($1.bestPrice ?? .max) }
    }
}

extension WidgetDestination {
    static let samples = [
        WidgetDestination(title: String(localized: "Алматы → Будапешт"), originCode: "ALA", destinationCode: "BUD",
                          month: "2026-11", includeNearby: false, threshold: 70000, currency: "kzt",
                          bestPrice: 66254, bestDate: "2026-11-16"),
        WidgetDestination(title: String(localized: "Астана → Будапешт"), originCode: "NQZ", destinationCode: "BUD",
                          month: "2026-11", includeNearby: false, threshold: nil, currency: "kzt",
                          bestPrice: 83104, bestDate: "2026-11-24")
    ]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PriceEntry {
        PriceEntry(date: Date(), destinations: WidgetDestination.samples)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PriceEntry) -> Void) {
        let saved = SharedStore.load()?.destinations ?? []
        let items = (context.isPreview && saved.isEmpty) ? WidgetDestination.samples : saved
        completion(PriceEntry(date: Date(), destinations: items))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PriceEntry>) -> Void) {
        Task {
            var items = SharedStore.load()?.destinations ?? []
            
            for i in items.indices {
                let d = items[i]
                
                if let response = try? await APIClient.shared.fetchPrices(origin: d.originCode, destination: d.destinationCode, month: d.month, nearby: d.includeNearby, currency: d.currency) {
                    let best = response.noFreshPrices ? nil : response.cheapest.first
                    items[i].bestPrice = best?.price
                    items[i].bestDate = best?.date
                    
                }
            }
            SharedStore.save(WidgetSnapshot(destinations: items, updatedAt: Date()), reloadWidgets: false)
            let entry = PriceEntry(date: Date(), destinations: items)
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3 * 3600))))
        }
    }
}

// Цвета виджета. Виджет — отдельный модуль, поэтому свои копии цветов приложения.
enum WidgetTheme {
    // Фирменный синий (как на иконке приложения)
    static let brandLight = Color(red: 0.12, green: 0.45, blue: 0.96)
    static let brandDark = Color(red: 0.04, green: 0.18, blue: 0.70)

    static var gradient: LinearGradient {
        LinearGradient(colors: [brandLight, brandDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Цвет выгодной цены: тёмно-зелёный на светлом фоне, светло-зелёный на тёмном
    static let good = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.36, green: 0.86, blue: 0.55, alpha: 1)
        : UIColor(red: 0.04, green: 0.52, blue: 0.28, alpha: 1) })

    // Мягкий фон среднего виджета: светло-голубой днём, тёмно-синий ночью
    static var softBackground: LinearGradient {
        let top = Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.14, blue: 0.28, alpha: 1)
            : UIColor(red: 0.90, green: 0.94, blue: 1.00, alpha: 1) })
        let bottom = Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.08, blue: 0.17, alpha: 1)
            : UIColor(red: 0.98, green: 0.99, blue: 1.00, alpha: 1) })
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}

// Круглая иконка с самолётом
private struct PlaneBadge: View {
    var size: CGFloat
    var onGradient: Bool          // true — на синем фоне (полупрозрачный белый круг)

    var body: some View {
        ZStack {
            if onGradient {
                Circle().fill(Color.white.opacity(0.22))
            } else {
                Circle().fill(WidgetTheme.gradient)
            }
            Image(systemName: "airplane")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-38))
        }
        .frame(width: size, height: size)
    }
}

struct FlighthunterWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PriceEntry
    
    var body: some View {
        Group {
            if entry.destinations.isEmpty {
                emptyView
            } else if family == .systemSmall {
                smallView
            } else {
                mediumView
            }
        }
        // Маленький виджет и пустое состояние — на синем градиенте, средний — на мягком светлом фоне
        .containerBackground(for: .widget) {
            if entry.destinations.isEmpty || family == .systemSmall {
                WidgetTheme.gradient
            } else {
                WidgetTheme.softBackground
            }
        }
    }
    
    // Направлений ещё нет
    private var emptyView: some View {
        VStack(spacing: 8) {
            PlaneBadge(size: 38, onGradient: true)
            Text("Добавьте направление в приложении")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Маленький: одна лучшая цена среди всех направлений
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                PlaneBadge(size: 24, onGradient: true)
                Text("Лучшая цена")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 4)
            if let best = entry.best, let price = best.bestPrice {
                Text(Format.price(price, currency: best.currency))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(best.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    if let date = best.bestDate {
                        Text(Format.day(date))
                    }
                    // Галочка: цена ниже вашего порога
                    if best.isBelowThreshold {
                        Image(systemName: "checkmark.seal.fill")
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 1)
            } else {
                Text("Нет свежих цен")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // Большой полупрозрачный самолёт для настроения
        .background(alignment: .bottomTrailing) {
            Image(systemName: "airplane")
                .font(.system(size: 76, weight: .semibold))
                .rotationEffect(.degrees(-38))
                .foregroundStyle(.white.opacity(0.14))
                .offset(x: 18, y: 14)
        }
    }
    
    // Средний: до трёх направлений списком
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                PlaneBadge(size: 22, onGradient: false)
                Text("Цены на билеты")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            ForEach(entry.destinations.prefix(3)) { d in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(d.title)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                        Text(Format.month(d.month))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    if let price = d.bestPrice {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(Format.price(price, currency: d.currency))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(d.isBelowThreshold ? WidgetTheme.good : .primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if let date = d.bestDate {
                                Text(Format.day(date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("Нет цен")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FlightHunterWidget: Widget {
    let kind: String = "FlightHunterWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FlighthunterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Цены на билеты")
        .description("Лучшая текущая цена по вашим направлениям.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall){
    FlightHunterWidget()
} timeline: {
    PriceEntry(date: .now, destinations: WidgetDestination.samples)
}
#Preview(as: .systemMedium){
    FlightHunterWidget()
} timeline: {
    PriceEntry(date: .now, destinations: WidgetDestination.samples)
}
