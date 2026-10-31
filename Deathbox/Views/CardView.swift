import SwiftUI

/// A face-up playing card.
struct CardView: View {
    let card: Card
    var width: CGFloat = 70

    private var height: CGFloat { width * 1.4 }
    private var ink: Color { card.suit.isRed ? Theme.blood : .black }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)

            VStack(spacing: 0) {
                HStack {
                    VStack(spacing: -2) {
                        Text(card.rankLabel).font(.system(size: width * 0.24, weight: .bold, design: .rounded))
                        Text(card.suit.symbol).font(.system(size: width * 0.18))
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(width * 0.07)

            Text(card.suit.symbol)
                .font(.system(size: width * 0.5))
                .offset(y: width * 0.08)
        }
        .foregroundStyle(ink)
        .frame(width: width, height: height)
        .accessibilityLabel("\(card.rankLabel) of \(String(describing: card.suit))")
    }
}

/// A face-down card, used for the draw pile.
struct CardBackView: View {
    var width: CGFloat = 70

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.12)
            .fill(LinearGradient(colors: [Theme.blood, Color(red: 0.4, green: 0.02, blue: 0.06)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.09)
                    .strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5)
                    .padding(width * 0.06)
            )
            .overlay(Text("☠").font(.system(size: width * 0.45)).foregroundStyle(.white.opacity(0.85)))
            .frame(width: width, height: width * 1.4)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
    }
}

#Preview {
    HStack {
        CardView(card: Card(rank: 14, suit: .spades))
        CardView(card: Card(rank: 10, suit: .hearts))
        CardBackView()
    }
    .padding()
    .background(Theme.felt)
}
