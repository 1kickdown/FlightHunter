//
//  AddDestinationView.swift
//  FlightHunter
//
//  Created by kickdown on 08.10.2026.
//

import SwiftUI
import SwiftData


private struct MonthOption: Identifiable {
    let key: String
    let title: String
    var id: String { key }
}



struct AddDestinationView: View {
    // Если открыта из подсказки на пустом экране, города выбираются сами
    var preset: RoutePreset? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let citiesStore = CitiesStore.shared
    
    
    @State private var origin: City?
    @State private var destination: City?
    @State private var month = AddDestinationView.months[0].key
    @State private var thresholdText = ""
    @State private var includeNearby = false
    @State private var currency = Currencies.initialChoice
    @State private var presetApplied = false
    
    
    private static let months: [MonthOption] = {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        
        let start = calendar.date(from: calendar.dateComponents([.year, .month] , from: Date()))!
        return (0..<12)
            .compactMap { calendar.date(byAdding: .month, value: $0, to : start) }
            .map { date in
                let key = formatter.string(from: date)
                return MonthOption(key: key, title: Format.month(key))
            }
    }()
    
    private var canSave: Bool {
        guard let origin, let destination else { return false }
        return origin.code != destination.code
    }
    
    
    
    // Цвета значков в строках формы
    private let departureColor = Theme.brandLight
    private let arrivalColor = Color(red: 0.0, green: 0.62, blue: 0.80)
    private let monthColor = Color(red: 1.0, green: 0.58, blue: 0.0)
    private let currencyColor = Color(red: 0.20, green: 0.68, blue: 0.35)
    private let thresholdColor = Color(red: 0.92, green: 0.25, blue: 0.38)
    private let nearbyColor = Color(red: 0.55, green: 0.35, blue: 0.95)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    routeHero
                        .padding(.bottom, 8)
                    
                    sectionTitle("Маршрут")
                    card { routeRows }
                    
                    sectionTitle("Когда")
                    card {
                        HStack {
                            FormRowLabel(icon: "calendar", color: monthColor, title: "Месяц")
                            Spacer()
                            Picker("Месяц", selection: $month) {
                                ForEach(Self.months) { Text($0.title).tag($0.key) }
                            }
                            .labelsHidden()
                        }
                    }
                    
                    sectionTitle("Цена")
                    card {
                        HStack {
                            FormRowLabel(icon: "banknote", color: currencyColor, title: "Валюта")
                            Spacer()
                            // Компактное меню: в строке коротко («USD · $»), в списке полные названия
                            Menu {
                                Picker("Валюта", selection: $currency) {
                                    ForEach(Currencies.all, id: \.self) { code in
                                        Text("\(Currencies.name(code)) · \(code.uppercased())").tag(code)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(verbatim: "\(currency.uppercased()) · \(Format.symbol(for: currency))")
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.footnote.weight(.semibold))
                                }
                                .foregroundStyle(Theme.accent)
                            }
                        }
                        Divider().padding(.vertical, 10)
                        // Порог задаётся в выбранной валюте, знак валюты подставляется в подсказку
                        HStack(spacing: 12) {
                            IconTile(systemName: "bell.badge.fill", color: thresholdColor)
                            TextField("Порог, \(Format.symbol(for: currency)) (необязательно)", text: $thresholdText)
                                .keyboardType(.numberPad)
                        }
                    }
                    footnote("Сообщим, когда цена станет ниже этой суммы.")
                    
                    card {
                        Toggle(isOn: $includeNearby) {
                            FormRowLabel(icon: "arrow.triangle.branch", color: nearbyColor,
                                         title: "Искать через соседние города")
                        }
                    }
                    .padding(.top, 8)
                    footnote("Если по вашему городу нет цен, включите: покажем варианты из ближайших аэропортов.")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background { ThemeBackground() }
            .navigationTitle("Новое направление")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", systemImage: "xmark") { dismiss() }
                        .labelStyle(.iconOnly)
                }
            }
            // Главная кнопка всегда под рукой внизу экрана
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text("Добавить направление")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.45)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .task { await citiesStore.load() }
        }
    }
    
    // MARK: - Сводка маршрута
    
    // Градиентная карточка вверху: коды городов крупно и кнопка «поменять местами»
    private var routeHero: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                codeBlock(code: origin?.code, name: origin?.displayName ?? String(localized: "Откуда"),
                          alignment: .leading)
                Spacer(minLength: 8)
                Button {
                    let previous = origin
                    origin = destination
                    destination = previous
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2), in: Circle())
                }
                .disabled(origin == nil && destination == nil)
                .accessibilityLabel("Поменять местами")
                Spacer(minLength: 8)
                codeBlock(code: destination?.code, name: destination?.displayName ?? String(localized: "Куда"),
                          alignment: .trailing)
            }
            Text(verbatim: "\(Format.month(month)) · \(currency.uppercased())")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.brandDark.opacity(0.35), radius: 14, y: 8)
    }
    
    private func codeBlock(code: String?, name: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(code ?? "···")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(code == nil ? 0.5 : 1))
            Text(name)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
    }
    
    // MARK: - Элементы оформления
    
    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 6)
            .padding(.top, 6)
    }
    
    private func footnote(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
    }
    
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .cardStyle()
    }
    
    // Строка «Откуда»/«Куда»: иконка, название, выбранный город и стрелка
    private func cityRow(icon: String, color: Color, title: LocalizedStringKey, value: String?) -> some View {
        HStack {
            FormRowLabel(icon: icon, color: color, title: title)
            Spacer()
            Text(value ?? String(localized: "Выбрать"))
                .foregroundStyle(value == nil ? Color.secondary : Color.primary)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var routeRows: some View {
        switch citiesStore.state {
        case .idle, .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Загружаем города…").foregroundStyle(.secondary)
                Spacer()
            }
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Button("Повторить") { Task { await citiesStore.load() } }
            }
        case .loaded(let cities):
            NavigationLink {
                CityPickerView(title: "Откуда", cities: cities, selection: $origin)
            } label: {
                cityRow(icon: "airplane.departure", color: departureColor, title: "Откуда",
                        value: origin?.displayName)
            }
            .buttonStyle(.plain)
            // Как только список городов готов, подставляем маршрут-подсказку (один раз)
            .onAppear { applyPreset(cities) }
            Divider().padding(.vertical, 10)
            NavigationLink {
                CityPickerView(title: "Куда", cities: cities, selection: $destination)
            } label: {
                cityRow(icon: "airplane.arrival", color: arrivalColor, title: "Куда",
                        value: destination?.displayName)
            }
            .buttonStyle(.plain)
        }
    }

    // Выбирает города из подсказки на пустом экране
    private func applyPreset(_ cities: [City]) {
        guard !presetApplied, let preset else { return }
        presetApplied = true
        origin = cities.first { $0.code == preset.origin }
        destination = cities.first { $0.code == preset.destination }
    }

    private func save() {
        guard let origin, let destination else { return }

        let threshold = Int(thresholdText.filter(\.isNumber)).flatMap { $0 > 0 ? $0 : nil }
        context.insert(Destination(
            originCode: origin.code, originName: origin.name,
            destinationCode: destination.code, destinationName: destination.name,
            month: month, threshold: threshold, includeNearby: includeNearby,
            originNameEn: origin.nameEn, destinationNameEn: destination.nameEn, currency: currency))
        Currencies.remember(currency)
        // Самый подходящий момент спросить про уведомления: пользователь только что начал следить за ценой
        Task { await PushPermission.requestIfNeeded() }
        dismiss()
    }
    
}

#Preview {
    AddDestinationView()
}
