//
//  BestDealCard.swift
//  FlightHunter
//
//  Яркая карточка вверху списка: самая выгодная цена среди направлений.
//

import SwiftUI

struct BestDealCard: View {
    let route: String   // "Астана → Будапешт"
    let price: String   // "78 456 ₸"
    let date: String    // "30 нояб."

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Самая выгодная цена сейчас", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(price)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(route) · \(date)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Image(systemName: "airplane")
                .font(.system(size: 56, weight: .semibold))
                .rotationEffect(.degrees(-38))
                .foregroundStyle(.white.opacity(0.28))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Theme.brandDark.opacity(0.35), radius: 14, y: 8)
    }
}
