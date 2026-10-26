//
//  DestinationDetailView.swift
//  FlightHunter
//
//  Created by kickdown on 09.10.2026.
//
//  Экран направления: шапка с лучшей ценой месяца, переключатель месяцев,
//  календарь цен и список самых дешёвых дат с кнопкой «Купить».
//

import SwiftUI

struct DestinationDetailView: View {
    let destination: Destination
    
    @State private var month: String
    @State private var state: PriceState = .loading
    @Environment(\.openURL) private var openURL     // открывает ссылку в Safari
    @State private var buyingID: String?            // у какой даты сейчас готовится ссылка
    @State private var buyError: String?            // текст ошибки, если ссылку получить не удалось
    
    init(destination: Destination){
        self.destination = destination
        _month = State(initialValue: destination.month)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                monthSwitcher
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background { ThemeBackground() }
        .navigationTitle(destination.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: month) { await load(showSpinner: true) }
        .refreshable {
            await load(showSpinner: false)
        }
        .alert("Не удалось открыть Aviasales",
               isPresented: Binding(get: { buyError != nil },
                                    set: { if !$0 { buyError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(buyError ?? "")
        }
    }
    
    // MARK: - Шапка с лучшей ценой месяца
    
    @ViewBuilder
    private var hero: some View {
        switch state {
        case .loading:
            heroContainer {
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBar(width: 170, height: 12, color: .white)
                    SkeletonBar(width: 150, height: 38, color: .white)
                    SkeletonBar(width: 120, height: 14, color: .white)
                }
            }
        case .failed:
            EmptyView()
        case .loaded(let response):
            if let best = response.cheapest.first, !response.noFreshPrices {
                let belowThreshold = destination.threshold.map { best.price <= $0 } ?? false
                heroContainer {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Лучшая цена в этом месяце", systemImage: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                        Text(Format.price(best.price, currency: destination.currency))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("\(Format.day(best.date)) · \(transfersText(best.transfers))")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.95))
                        if belowThreshold || destination.includeNearby {
                            HStack(spacing: 6) {
                                if belowThreshold {
                                    Badge("Ниже порога", systemImage: "checkmark.circle.fill", color: .white)
                                }
                                if destination.includeNearby {
                                    Badge("через соседние города", systemImage: "arrow.triangle.branch", color: .white)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }
    
    // Градиентная подложка шапки с полупрозрачным самолётом
    private func heroContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack(alignment: .trailing) {
            content().frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "airplane")
                .font(.system(size: 64, weight: .semibold))
                .rotationEffect(.degrees(-38))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(20)
        .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.brandDark.opacity(0.35), radius: 14, y: 8)
    }
    
    // MARK: - Переключатель месяцев
    
    private var canGoBack: Bool { month > Format.currentMonth() }
    private var canGoForward: Bool {
        guard let last = Format.shiftMonth(Format.currentMonth(), by: 11) else { return false }
        return month < last
    }
    
    private func shift(_ n: Int) {
        if let next = Format.shiftMonth(month, by: n) { month = next }
    }
    
    private var monthSwitcher: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                .buttonStyle(CircleIconButtonStyle())
                .disabled(!canGoBack)
            Spacer()
            Text(Format.month(month))
                .font(.system(.title3, design: .rounded).weight(.bold))
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .buttonStyle(CircleIconButtonStyle())
                .disabled(!canGoForward)
        }
    }
    
    // MARK: - Содержимое по состоянию загрузки
    
    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            loadingCards
        
        case .failed(let message):
            VStack(spacing: 14) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 34))
                    .foregroundStyle(.orange)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Повторить") { Task { await load(showSpinner: true) } }
                    .buttonStyle(GradientButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .cardStyle()
        
        case .loaded(let response):
            if response.noFreshPrices || response.days.isEmpty {
                // Данных нет, это не ошибка
                VStack(spacing: 10) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)
                    Text("Нет свежих цен")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text("На этот месяц данных пока нет. Попробуйте другой месяц или включите поиск через соседние города.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .cardStyle()
            } else {
                VStack(spacing: 12) {
                    PriceCalendarView(month: month, days: response.days,
                                      threshold: destination.threshold,
                                      onSelect: { day in Task { await buy(day) } })
                    legend
                }
                .cardStyle()
                cheapestList(response.cheapest)
                Text("Цены ориентировочные. Билеты покупаются на сайте Aviasales.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }
    
    // «Скелетоны» календаря и списка, пока грузятся цены
    private var loadingCards: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { _ in
                            SkeletonBar(width: 38, height: 44)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            SkeletonBar(width: 110, height: 16)
                            SkeletonBar(width: 80, height: 11)
                        }
                        Spacer()
                        SkeletonBar(width: 90, height: 28)
                    }
                }
            }
            .cardStyle()
        }
    }
    
    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.brandLight)
                    .frame(width: 14, height: 14)
                Text("Лучшая цена")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.good.opacity(0.3))
                    .frame(width: 14, height: 14)
                Group {
                    if destination.threshold == nil {
                        Text("Зелёные: самые дешёвые дни месяца")
                    } else {
                        Text("Зелёные: цена в пределах вашего порога")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Список самых дешёвых дат
    
    private func cheapestList(_ days: [Day]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Самые дешёвые даты")
                .font(.system(.headline, design: .rounded))
                .padding(.bottom, 6)
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            if index == 0 {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.good)
                            }
                            // "16 нояб." или "16 нояб. → 23 нояб.", если билет туда-обратно
                            Text(dateText(day))
                                .font(.body.weight(.semibold))
                        }
                        Text(details(day))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Text(Format.price(day.price, currency: destination.currency))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(index == 0 ? Theme.good : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Button {
                        Task { await buy(day) }
                    } label: {
                        if buyingID == day.id {
                            ProgressView().tint(.white)
                        } else {
                            Text("Купить")
                        }
                    }
                    .buttonStyle(CTAButtonStyle())
                    .disabled(buyingID != nil)
                }
                .padding(.vertical, 10)
                if index < days.count - 1 { Divider() }
            }
        }
        .cardStyle()
    }
    
    private func dateText(_ day: Day) -> String {
        var text = Format.day(day.date)
        if let back = day.returnDate { text += " → \(Format.day(back))" }
        return text
    }
    
    private func details(_ day: Day) -> String {
        var parts = [transfersText(day.transfers)]
        if day.origin != destination.originCode { parts.append(String(localized: "из \(day.origin)")) }
        return parts.joined(separator: " · ")
    }
    
    private func transfersText(_ n: Int) -> String {
        // Склонение («1 пересадка», «2 пересадки», «5 пересадок») задано в каталоге строк
        if n == 0 { return String(localized: "прямой рейс") }
        return String(localized: "\(n) пересадок")
    }
    
    // Запрашивает у нашего бэкенда партнёрскую ссылку и открывает поиск на Aviasales.
    private func buy(_ day: Day) async {
        guard buyingID == nil else { return }   // уже готовится другая ссылка
        buyingID = day.id
        defer { buyingID = nil }
        do {
            let url = try await APIClient.shared.fetchBuyLink(
                origin: day.origin, destination: day.destination,
                date: day.date, returnDate: day.returnDate)
            openURL(url)
        } catch {
            buyError = error.localizedDescription
        }
    }

    private func load(showSpinner: Bool) async {
        if showSpinner { state = .loading }
        do {
            let response = try await APIClient.shared.fetchPrices(
                origin: destination.originCode, destination: destination.destinationCode,
                month: month, nearby: destination.includeNearby, currency: destination.currency)
            guard !Task.isCancelled else { return }
            state = .loaded(response)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
        }
    }
}
