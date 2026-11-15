import SwiftUI

struct DestinationRow: View {
    let destination : Destination
    let state: PriceState
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RouteIcon(size: 46)
            VStack(alignment: .leading, spacing: 6) {
                Text(destination.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                priceBlock
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .cardStyle()
    }
    
    private var subtitle: String {
        "\(destination.originCode) → \(destination.destinationCode) · \(Format.month(destination.month))"
    }
    
    @ViewBuilder
    private var priceBlock: some View {
        switch state {
        case .loading:
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(width: 130, height: 24)
                SkeletonBar(width: 90, height: 12)
            }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(.orange)
        case .loaded(let response):
            if let best = response.cheapest.first, !response.noFreshPrices {
                let belowThreshold = destination.threshold.map { best.price <= $0 } ?? false
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("от \(Format.price(best.price, currency: destination.currency))")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(belowThreshold ? Theme.good : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(Format.day(best.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    badges(belowThreshold: belowThreshold)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Нет свежих цен", systemImage: "moon.zzz")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    badges(belowThreshold: false)
                }
            }
        }
    }
    
    @ViewBuilder
    private func badges(belowThreshold: Bool) -> some View {
        if belowThreshold || destination.includeNearby {
            HStack(spacing: 6) {
                if belowThreshold {
                    Badge("Ниже порога", systemImage: "checkmark.circle.fill", color: Theme.good)
                }
                if destination.includeNearby {
                    Badge("через соседние города", systemImage: "arrow.triangle.branch", color: Theme.accent)
                }
            }
        }
    }
}
