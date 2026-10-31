import Foundation

enum Call {
    case higher, lower
    var label: String { self == .higher ? "Higher" : "Lower" }
}

enum TieRule: String, CaseIterable, Identifiable {
    case wrong = "Tie counts as wrong"
    case correct = "Tie counts as correct"
    var id: String { rawValue }
}

struct GameSettings {
    var aceHigh = true
    var tieRule: TieRule = .wrong
    var streakToPass = 3
}

struct Position: Hashable {
    let row: Int
    let col: Int
}

struct GuessResult: Identifiable {
    let id = UUID()
    let playerName: String
    let call: Call
    let previous: Card
    let drawn: Card
    let correct: Bool
    let passedTurn: Bool
}

/// The penalty that happens after a wrong call: the player drinks while
/// everyone else takes turns counting up to the size of the stack.
struct Penalty: Identifiable {
    enum Outcome {
        /// The counters reached the number before the drink was finished.
        case countersFinished
        /// The drinker finished first; the counter who was up drinks for the rest of the count.
        case drinkerFinished(counter: Int, remaining: Int)
    }

    let id = UUID()
    let drinker: Int
    let target: Int
    /// Player indices in counting order (everyone but the drinker).
    let counters: [Int]
    var count = 0
    var outcome: Outcome?

    /// Who says the next number.
    var nextCounter: Int { counters[count % counters.count] }
}

enum Phase {
    case playing
    case eliminate
    case gameOver
}

final class GameEngine: ObservableObject {
    let players: [String]
    let settings: GameSettings

    /// grid[row][col] is a stack of cards; the last card is the face-up top card.
    @Published private(set) var grid: [[[Card]]] = []
    @Published private(set) var deck: [Card] = []
    @Published private(set) var currentPlayer = 0
    @Published private(set) var streak = 0
    @Published private(set) var lastResult: GuessResult?
    @Published var penalty: Penalty?
    @Published private(set) var penaltiesTaken: [Int]
    @Published private(set) var round = 1

    init(players: [String], settings: GameSettings) {
        precondition(players.count >= 2, "Deathbox needs at least 2 players")
        self.players = players
        self.settings = settings
        self.penaltiesTaken = Array(repeating: 0, count: players.count)
        deal()
    }

    var rows: Int { grid.count }
    var cols: Int { grid.first?.count ?? 0 }
    var currentPlayerName: String { players[currentPlayer] }

    var phase: Phase {
        if grid.isEmpty || cols == 0 { return .gameOver }
        if deck.isEmpty { return .eliminate }
        return .playing
    }

    func deal() {
        var cards = Card.fullDeck().shuffled()
        var newGrid: [[[Card]]] = []
        for _ in 0..<4 {
            var row: [[Card]] = []
            for _ in 0..<4 { row.append([cards.removeLast()]) }
            newGrid.append(row)
        }
        grid = newGrid
        deck = cards
        currentPlayer = 0
        streak = 0
        lastResult = nil
        penalty = nil
        round = 1
        penaltiesTaken = Array(repeating: 0, count: players.count)
    }

    func stack(at p: Position) -> [Card] { grid[p.row][p.col] }

    /// The current player points at a stack and calls higher or lower.
    @discardableResult
    func makeCall(_ call: Call, at p: Position) -> GuessResult? {
        guard phase == .playing, penalty == nil,
              grid.indices.contains(p.row), grid[p.row].indices.contains(p.col),
              let previous = grid[p.row][p.col].last,
              let drawn = deck.popLast() else { return nil }

        grid[p.row][p.col].append(drawn)

        let a = previous.value(aceHigh: settings.aceHigh)
        let b = drawn.value(aceHigh: settings.aceHigh)
        let correct: Bool
        if a == b {
            correct = settings.tieRule == .correct
        } else {
            correct = call == .higher ? b > a : b < a
        }

        let name = currentPlayerName
        var passed = false
        if correct {
            streak += 1
            if streak >= settings.streakToPass {
                passed = true
                streak = 0
                currentPlayer = (currentPlayer + 1) % players.count
            }
        } else {
            streak = 0
            penaltiesTaken[currentPlayer] += 1
            let others = (1..<players.count).map { (currentPlayer + $0) % players.count }
            penalty = Penalty(drinker: currentPlayer,
                              target: grid[p.row][p.col].count,
                              counters: others)
        }

        let result = GuessResult(playerName: name, call: call, previous: previous,
                                 drawn: drawn, correct: correct, passedTurn: passed)
        lastResult = result
        return result
    }

    // MARK: Penalty counting

    /// A counter said the next number out loud.
    func countNextNumber() {
        guard var pen = penalty, pen.outcome == nil else { return }
        pen.count += 1
        if pen.count >= pen.target { pen.outcome = .countersFinished }
        penalty = pen
    }

    /// The drinker finished their drink before the count was done.
    func drinkerFinished() {
        guard var pen = penalty, pen.outcome == nil else { return }
        pen.outcome = .drinkerFinished(counter: pen.nextCounter, remaining: pen.target - pen.count)
        penalty = pen
    }

    func dismissPenalty() { penalty = nil }

    // MARK: Elimination

    /// When the deck runs out, the current player removes a row; those cards become the new deck.
    func eliminateRow(_ r: Int) {
        guard phase == .eliminate, grid.indices.contains(r) else { return }
        let removed = grid.remove(at: r).flatMap { $0 }
        refill(with: removed)
    }

    /// When the deck runs out, the current player removes a column; those cards become the new deck.
    func eliminateColumn(_ c: Int) {
        guard phase == .eliminate, (0..<cols).contains(c) else { return }
        var removed: [Card] = []
        for r in grid.indices { removed.append(contentsOf: grid[r].remove(at: c)) }
        if cols == 0 { grid = [] }
        refill(with: removed)
    }

    private func refill(with cards: [Card]) {
        if grid.isEmpty {
            deck = []
        } else {
            deck = cards.shuffled()
            round += 1
        }
        lastResult = nil
    }
}

extension Penalty.Outcome: Equatable {}
