//
//  EmptyStateView.swift
//  FlightHunter
//
//  Первый экран, пока нет ни одного направления: приветствие, главная кнопка
//  и быстрые подсказки популярных маршрутов.
//

import SwiftUI

// Готовый маршрут для быстрого добавления: форма откроется с уже выбранными городами
struct RoutePreset: Identifiable, Equatable {
    let origin: String       // код IATA
    let destination: String
    let label: String        // подпись на кнопке
    var id: String { origin + destination }

    // Популярные маршруты нашей аудитории
    static var popular: [RoutePreset] {
        [
            RoutePreset(origin: "ALA", destination: "BUD", label: String(localized: "Алматы → Будапешт")),
            RoutePreset(origin: "NQZ", destination: "IST", label: String(localized: "Астана → Стамбул")),
            RoutePreset(origin: "ALA", destination: "VIE", label: String(localized: "Алматы → Вена")),
        ]
    }
}

struct EmptyStateView: View {
    let onAdd: () -> Void
    let onPick: (RoutePreset) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Большая иконка, которая слегка «парит»
                ZStack {
                    Circle().fill(Theme.gradient)
                    Image(systemName: "airplane")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-38))
                }
                .frame(width: 124, height: 124)
                .shadow(color: Theme.brandDark.opacity(0.35), radius: 18, y: 10)
                .phaseAnimator([0.0, -8.0]) { content, offset in
                    content.offset(y: offset)
                } animation: { _ in
                    .easeInOut(duration: 2)
                }
                .padding(.top, 36)
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Куда полетим?")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Добавьте маршрут, и мы будем следить за ценами.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Button(action: onAdd) {
                    Label("Добавить направление", systemImage: "plus")
                }
                .buttonStyle(GradientButtonStyle())
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Популярные маршруты")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    ForEach(RoutePreset.popular) { preset in
                        Button { onPick(preset) } label: {
                            HStack(spacing: 12) {
                                RouteIcon(size: 36)
                                Text(preset.label)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .cardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 32)
        }
    }
}
