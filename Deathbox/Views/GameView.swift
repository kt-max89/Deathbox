import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameEngine
    let onQuit: () -> Void

    @State private var selected: Position?
    @State private var confirmQuit = false
    @State private var showRules = false
    @State private var feedbackTick = 0
    @State private var lastWasCorrect = true

    private let spacing: CGFloat = 8
    private let eliminateButtonSize: CGFloat = 34

    var body: some View {
        VStack(spacing: 12) {
            header
            if game.phase == .gameOver {
                gameOver
            } else {
                gridArea
                resultBanner
                controls
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .fullScreenCover(item: $game.penalty) { _ in
            PenaltyView(game: game)
        }
        .sheet(isPresented: $showRules) { RulesView() }
        .confirmationDialog("Quit this game?", isPresented: $confirmQuit, titleVisibility: .visible) {
            Button("Quit game", role: .destructive, action: onQuit)
        }
        .sensoryFeedback(lastWasCorrect ? SensoryFeedback.success : SensoryFeedback.error, trigger: feedbackTick)
        .onChange(of: game.rows) { _, _ in selected = nil }
        .onChange(of: game.cols) { _, _ in selected = nil }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button { confirmQuit = true } label: { Image(systemName: "xmark.circle.fill") }
                Spacer()
                Text("Round \(game.round)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Button { showRules = true } label: { Image(systemName: "questionmark.circle.fill") }
            }
            .font(.title2)
            .foregroundStyle(.white.opacity(0.8))

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.phase == .eliminate ? "Deck's empty!" : "Up now")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(game.currentPlayerName)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    HStack(spacing: 6) {
                        ForEach(0..<game.settings.streakToPass, id: \.self) { i in
                            Circle()
                                .fill(i < game.streak ? Theme.good : Color.white.opacity(0.2))
                                .frame(width: 14, height: 14)
                        }
                        Text("\(game.streak)/\(game.settings.streakToPass) in a row")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    if game.deck.isEmpty {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            .frame(width: 46, height: 64)
                    } else {
                        CardBackView(width: 46)
                    }
                    Text("\(game.deck.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(.black.opacity(0.75)))
                        .offset(x: 8, y: 6)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: Grid

    private var gridArea: some View {
        GeometryReader { geo in
            let eliminating = game.phase == .eliminate
            let reserve = eliminating ? eliminateButtonSize + spacing : 0
            let cols = CGFloat(max(game.cols, 1))
            let rows = CGFloat(max(game.rows, 1))
            let byWidth = (geo.size.width - reserve - spacing * (cols - 1)) / cols
            let byHeight = ((geo.size.height - reserve - spacing * (rows - 1)) / rows) / 1.4
            let w = max(30, min(byWidth, byHeight, 120))

            VStack(spacing: spacing) {
                if eliminating {
                    HStack(spacing: spacing) {
                        Color.clear.frame(width: eliminateButtonSize, height: eliminateButtonSize)
                        ForEach(0..<game.cols, id: \.self) { c in
                            eliminateButton("Remove column \(c + 1)", systemImage: "arrow.down") {
                                withAnimation(.spring) { game.eliminateColumn(c) }
                            }
                            .frame(width: w)
                        }
                    }
                }
                ForEach(0..<game.rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        if eliminating {
                            eliminateButton("Remove row \(r + 1)", systemImage: "arrow.right") {
                                withAnimation(.spring) { game.eliminateRow(r) }
                            }
                        }
                        ForEach(0..<game.cols, id: \.self) { c in
                            stackCell(Position(row: r, col: c), width: w)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func stackCell(_ p: Position, width: CGFloat) -> some View {
        let stack = game.stack(at: p)
        let isSelected = selected == p
        return Button {
            guard game.phase == .playing else { return }
            withAnimation(.snappy) { selected = isSelected ? nil : p }
        } label: {
            ZStack(alignment: .topTrailing) {
                if let top = stack.last {
                    CardView(card: top, width: width)
                        .id(top.id)
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .opacity))
                }
                Text("\(stack.count)")
                    .font(.system(size: max(10, width * 0.16), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(stack.count >= 5 ? Theme.blood : Color.black.opacity(0.7)))
                    .offset(x: 5, y: -5)
            }
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.12)
                    .strokeBorder(Theme.gold, lineWidth: isSelected ? 3 : 0)
            )
            .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stack of \(stack.count)")
    }

    private func eliminateButton(_ label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(width: eliminateButtonSize, height: eliminateButtonSize)
                .background(Circle().fill(Theme.blood))
        }
        .accessibilityLabel(label)
    }

    // MARK: Result + controls

    @ViewBuilder
    private var resultBanner: some View {
        if let r = game.lastResult, game.phase == .playing {
            HStack(spacing: 10) {
                CardView(card: r.drawn, width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.correct ? (r.passedTurn ? "Survived! Next player." : "Correct!") : "Wrong! Drink!")
                        .font(.headline)
                        .foregroundStyle(r.correct ? Theme.good : Theme.blood)
                    Text("\(r.playerName) called \(r.call.label.lowercased()) on \(r.previous.rankLabel)\(r.previous.suit.symbol), drew \(r.drawn.rankLabel)\(r.drawn.suit.symbol)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.35)))
            .id(r.id)
            .transition(.opacity)
        } else if game.phase == .eliminate {
            Text("\(game.currentPlayerName), tap an ✕ to kill a row or column. Its cards become the new deck.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.blood.opacity(0.35)))
        } else {
            Text("Tap a stack, then call it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if game.phase == .playing {
            HStack(spacing: 12) {
                callButton(.lower, systemImage: "arrow.down", color: Color(red: 0.2, green: 0.45, blue: 0.95))
                callButton(.higher, systemImage: "arrow.up", color: Color(red: 0.95, green: 0.45, blue: 0.15))
            }
        }
    }

    private func callButton(_ call: Call, systemImage: String, color: Color) -> some View {
        Button {
            guard let p = selected else { return }
            let result = withAnimation(.spring(duration: 0.35)) { game.makeCall(call, at: p) }
            if let result {
                lastWasCorrect = result.correct
                feedbackTick += 1
            }
        } label: {
            Label(call.label, systemImage: systemImage)
                .font(.title3.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(RoundedRectangle(cornerRadius: 16).fill(color))
                .foregroundStyle(.white)
        }
        .disabled(selected == nil)
        .opacity(selected == nil ? 0.4 : 1)
    }

    // MARK: Game over

    private var gameOver: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("☠").font(.system(size: 80))
            Text("The box is dead").font(.largeTitle.weight(.black))
            VStack(spacing: 8) {
                Text("Wrong calls").font(.headline).foregroundStyle(.secondary)
                ForEach(game.players.indices.sorted { game.penaltiesTaken[$0] > game.penaltiesTaken[$1] },
                        id: \.self) { i in
                    HStack {
                        Text(game.players[i])
                        Spacer()
                        Text("\(game.penaltiesTaken[i])").monospacedDigit().bold()
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(.black.opacity(0.3)))
            Button {
                withAnimation { game.deal() }
            } label: {
                Text("Play again")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.blood))
                    .foregroundStyle(.white)
            }
            Button("New players", action: onQuit)
            Spacer()
        }
    }
}

#Preview {
    GameView(game: GameEngine(players: ["Kieran", "Alex", "Sam"], settings: GameSettings()), onQuit: {})
        .background(Theme.felt)
}
