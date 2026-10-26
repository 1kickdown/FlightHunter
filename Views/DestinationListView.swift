//
//  DestinationListView.swift
//  FlightHunter
//
//  Created by kickdown on 07.10.2026.
//

import SwiftUI
import SwiftData

// Что нужно показать в окне добавления направления
private struct AddRequest: Identifiable {
    let id = UUID()
    let preset: RoutePreset?
}

struct DestinationListView: View {
    @Environment(\.modelContext) private var context
    
    @Query( sort: \Destination.createdAt, order: .reverse) private var destinations: [Destination]
    
    @State private var store = PricesStore()
    @State private var showingAbout = false
    // Запрос на открытие формы добавления (с маршрутом-подсказкой или без него).
    // Через sheet(item:) маршрут гарантированно попадает в форму вместе с её открытием.
    @State private var addRequest: AddRequest?
    // Открытые экраны навигации; нужен, чтобы пуш мог открыть конкретное направление
    @State private var path: [Destination] = []
    private let router = AppRouter.shared
    
    
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if destinations.isEmpty {
                    emptyState
                }
                else {
                    list
                }
            }
            .background { ThemeBackground() }
            .navigationTitle("Направления")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingAbout = true } label: { Image(systemName: "info.circle") }
                        .accessibilityLabel("О приложении")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { addRequest = AddRequest(preset: nil) } label: { Image(systemName: "plus" ) }
                }
            }
            .sheet(item: $addRequest) { request in
                AddDestinationView(preset: request.preset)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .navigationDestination(for: Destination.self) { destination in
                DestinationDetailView(destination: destination)
            }
            .onChange(of: store.version) { syncWidget() }
            .onChange(of: destinations.count) { syncWidget() }
            // Передаём список на сервер: при открытии списка и при любом изменении направлений
            .onChange(of: syncDestinations) { syncToServer() }
            .task {
                syncToServer()
                await fillEnglishNames()
            }
            // Пользователь нажал на пуш: открываем нужное направление
            .onChange(of: router.pendingRoute, initial: true) { openPendingRoute() }
        }
    }
    
    private var emptyState: some View {
        EmptyStateView(
            onAdd: { addRequest = AddRequest(preset: nil) },
            onPick: { route in addRequest = AddRequest(preset: route) })
    }
    
    // Самая выгодная цена среди направлений. Цены в разных валютах сравнивать нельзя,
    // поэтому берём валюту самого нового направления с ценой и ищем минимум в ней.
    // Карточку показываем, только если есть из чего выбирать (минимум два направления).
    private var bestDeal: (destination: Destination, price: Int, date: String)? {
        let priced: [(destination: Destination, best: Day)] = destinations.compactMap { d in
            if case .loaded(let response) = store.state(for: d),
               !response.noFreshPrices, let best = response.cheapest.first {
                return (d, best)
            }
            return nil
        }
        guard let currency = priced.first?.destination.currency else { return nil }
        let sameCurrency = priced.filter { $0.destination.currency == currency }
        guard sameCurrency.count >= 2,
              let winner = sameCurrency.min(by: { $0.best.price < $1.best.price }) else { return nil }
        return (winner.destination, winner.best.price, winner.best.date)
    }
    
    private var list: some View {
        List {
            if let deal = bestDeal {
                Button { path = [deal.destination] } label: {
                    BestDealCard(route: deal.destination.title,
                                 price: Format.price(deal.price, currency: deal.destination.currency),
                                 date: Format.day(deal.date))
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            ForEach(destinations) { destination in
                // Невидимая ссылка поверх карточки: нажатие открывает экран, а стрелку рисует сама карточка
                ZStack {
                    NavigationLink(value: destination) { EmptyView() }
                        .opacity(0)
                    DestinationRow(destination: destination,
                                   state: store.state(for: destination))
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                .task { await store.load(destination) }
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            for destination in destinations {
                await store.load(destination, force: true)
            }
        }
    }
    
    private func delete( at offsets: IndexSet) {
        for index in offsets { context.delete(destinations[index] ) }
    }
    

    // Направления, сохранённые до появления английского языка, не имеют английских названий:
    // дозаполняем их из справочника городов.
    private func fillEnglishNames() async {
        guard destinations.contains(where: { $0.originNameEn == nil || $0.destinationNameEn == nil }) else { return }
        await CitiesStore.shared.load()
        guard case .loaded(let cities) = CitiesStore.shared.state else { return }
        let byCode = Dictionary(cities.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
        for d in destinations {
            if d.originNameEn == nil { d.originNameEn = byCode[d.originCode]?.nameEn }
            if d.destinationNameEn == nil { d.destinationNameEn = byCode[d.destinationCode]?.nameEn }
        }
        syncWidget()
    }

    private var syncDestinations: [SyncDestination] {
        destinations.map(SyncDestination.init)
    }

    private func syncToServer() {
        SyncService.shared.updateDestinations(syncDestinations)
    }

    // Находит направление из пуша среди сохранённых и открывает его экран
    private func openPendingRoute() {
        guard let route = router.pendingRoute else { return }
        if let match = destinations.first(where: {
            $0.originCode == route.origin && $0.destinationCode == route.destination &&
            $0.month == route.month && $0.includeNearby == route.nearby
        }) {
            path = [match]
        }
        router.pendingRoute = nil
    }

    private func syncWidget() {

        let previous = Dictionary(
            (SharedStore.load()?.destinations ?? []).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first })

        let items = destinations.map { d -> WidgetDestination in
            var item = WidgetDestination(
                title: d.title, originCode: d.originCode, destinationCode: d.destinationCode,
                month: d.month, includeNearby: d.includeNearby, threshold: d.threshold,
                currency: d.currency)
            switch store.state(for: d) {
            case .loaded(let response):
                let best = response.noFreshPrices ? nil : response.cheapest.first
                item.bestPrice = best?.price
                item.bestDate = best?.date
            case .loading, .failed:
                item.bestPrice = previous[item.id]?.bestPrice
                item.bestDate = previous[item.id]?.bestDate
            }
            return item
        }
        SharedStore.save(WidgetSnapshot(destinations: items, updatedAt: Date()))
    }

}

#Preview {
    DestinationListView()
}
