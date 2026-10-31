import SwiftUI

/// Shown after a wrong call. The drinker drinks while the others count to the
/// stack size, one number each. Tap the big area every time someone says a number.
struct PenaltyView: View {
    @ObservedObject var game: GameEngine
    @State private var countTick = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.35, green: 0.02, blue: 0.05), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if let pen = game.penalty {
                VStack(spacing: 18) {
                    header(pen)
                    if let outcome = pen.outcome {
                        outcomeView(outcome, pen)
                    } else {
                        countingView(pen)
                    }
                }
                .padding(20)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: countTick)
    }

    private func header(_ pen: Penalty) -> some View {
        VStack(spacing: 6) {
            Text("WRONG CALL")
                .font(.caption.weight(.heavy))
                .tracking(3)
                .foregroundStyle(Theme.blood)
            Text("\(game.players[pen.drinker]) drinks!")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text("Everyone else counts to \(pen.target), one number each.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private func countingView(_ pen: Penalty) -> some View {
        VStack(spacing: 18) {
            Button {
                game.countNextNumber()
                countTick += 1
            } label: {
                VStack(spacing: 10) {
                    Text("\(pen.count)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("of \(pen.target)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Divider().overlay(Color.white.opacity(0.2)).padding(.vertical, 6)
                    Text("Next: \(game.players[pen.nextCounter]) says “\(pen.count + 1)”")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.gold)
                        .multilineTextAlignment(.center)
                    Text("Tap here each time a number is said")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .animation(.snappy, value: pen.count)

            Button {
                withAnimation { game.drinkerFinished() }
                countTick += 1
            } label: {
                Text("🍺 \(game.players[pen.drinker]) finished the drink!")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.blood))
                    .foregroundStyle(.white)
            }

            Button("Skip penalty") { game.dismissPenalty() }
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func outcomeView(_ outcome: Penalty.Outcome, _ pen: Penalty) -> some View {
        VStack(spacing: 20) {
            Spacer()
            switch outcome {
            case .countersFinished:
                Text("⏱").font(.system(size: 80))
                Text("Counted to \(pen.target)!")
                    .font(.largeTitle.weight(.black))
                Text("\(game.players[pen.drinker]) can stop drinking.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case let .drinkerFinished(counter, remaining):
                Text("🔥").font(.system(size: 80))
                Text("Beat the count!")
                    .font(.largeTitle.weight(.black))
                Text("\(game.players[counter]) was up, so \(game.players[counter]) drinks for a count of \(remaining).")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button {
                game.dismissPenalty()
            } label: {
                Text("Back to the box")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                    .foregroundStyle(.black)
            }
        }
    }
}
