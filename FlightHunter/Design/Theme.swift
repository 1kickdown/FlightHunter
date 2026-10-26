//
//  Theme.swift
//  FlightHunter
//
//  Единое место для цветов, градиентов и стилей оформления приложения.
//  Чтобы поменять оттенки, достаточно править этот файл.
//

import SwiftUI
import UIKit

extension Color {
    // Цвет, который сам меняется между светлой и тёмной темой
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
}

enum Theme {
    // Фирменный синий (как на иконке приложения)
    static let brandLight = Color(red: 0.12, green: 0.45, blue: 0.96)
    static let brandDark = Color(red: 0.04, green: 0.18, blue: 0.70)

    static var gradient: LinearGradient {
        LinearGradient(colors: [brandLight, brandDark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Выгодная цена: тёмно-зелёный на светлом, светло-зелёный на тёмном (хороший контраст в обеих темах)
    static let good = Color.adaptive(light: Color(red: 0.04, green: 0.52, blue: 0.28),
                                     dark: Color(red: 0.36, green: 0.86, blue: 0.55))

    // Акцент для заметных кнопок («Купить»)
    static let cta = Color(red: 0.90, green: 0.38, blue: 0.0)

    // Цвет для текста и значков синего оттенка (в тёмной теме светлее)
    static let accent = Color.adaptive(light: Color(red: 0.10, green: 0.40, blue: 0.95),
                                       dark: Color(red: 0.40, green: 0.70, blue: 1.0))
}

// Фон экранов: мягкий голубой градиент (в тёмной теме — тёмно-синий)
struct ThemeBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.05, green: 0.09, blue: 0.20), Color(red: 0.03, green: 0.05, blue: 0.12)]
                : [Color(red: 0.86, green: 0.92, blue: 1.00), Color(red: 0.96, green: 0.98, blue: 1.00)],
            startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
}

// Карточка: скруглённая подложка с мягкой тенью
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(scheme == .dark ? Color.white.opacity(0.09) : Color.white)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.07), radius: 12, y: 5)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
