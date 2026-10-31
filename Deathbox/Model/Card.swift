import Foundation

enum Suit: CaseIterable {
    case spades, hearts, diamonds, clubs

    var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        }
    }

    var isRed: Bool { self == .hearts || self == .diamonds }
}

struct Card: Identifiable, Equatable {
    let id = UUID()
    /// 2...14, where 11 = J, 12 = Q, 13 = K, 14 = A
    let rank: Int
    let suit: Suit

    var rankLabel: String {
        switch rank {
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        case 14: return "A"
        default: return String(rank)
        }
    }

    func value(aceHigh: Bool) -> Int {
        (rank == 14 && !aceHigh) ? 1 : rank
    }

    static func fullDeck() -> [Card] {
        Suit.allCases.flatMap { suit in (2...14).map { Card(rank: $0, suit: suit) } }
    }
}
