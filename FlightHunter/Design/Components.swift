//
//  Components.swift
//  FlightHunter
//
//  Небольшие повторно используемые элементы оформления.
//

import SwiftUI

// Круглая иконка с самолётом на фирменном градиенте
struct RouteIcon: View {
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle().fill(Theme.gradient)
            Image(systemName: "airplane")
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-38))
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.brandDark.opacity(0.3), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}

// Небольшой цветной бейдж: «Ниже порога», «через соседние города»
struct Badge: View {
    let text: LocalizedStringKey
    let systemImage: String
    let color: Color

    init(_ text: LocalizedStringKey, systemImage: String, color: Color) {
        self.text = text
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
    }
}

// «Скелетон»: серая полоска, которая мягко мерцает, пока грузятся цены
struct SkeletonBar: View {
    var width: CGFloat
    var height: CGFloat
    var color: Color = .secondary      // на цветном фоне используем белый

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2.5, style: .continuous)
            .fill(color.opacity(0.25))
            .frame(width: width, height: height)
            .phaseAnimator([0.45, 1.0]) { content, opacity in
                content.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
    }
}

// Главная кнопка: капсула с градиентом
struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
            .background(Theme.gradient, in: Capsule())
            .shadow(color: Theme.brandDark.opacity(0.35), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Заметная оранжевая кнопка «Купить»
struct CTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Theme.cta, in: Capsule())
            .shadow(color: Theme.cta.opacity(0.35), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Круглая кнопка со значком (переключатель месяцев)
struct CircleIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .frame(width: 42, height: 42)
            .background(Circle().fill(scheme == .dark ? Color.white.opacity(0.1) : Color.white))
            .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.08), radius: 6, y: 3)
            .opacity(isEnabled ? 1 : 0.35)
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
    }
}

// Цветная иконка слева в строке формы (как в системных настройках)
struct IconTile: View {
    let systemName: String
    let color: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .accessibilityHidden(true)
    }
}

// Иконка и название строки формы
struct FormRowLabel: View {
    let icon: String
    let color: Color
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, color: color)
            Text(title)
        }
    }
}
