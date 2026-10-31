import SwiftUI

struct SetupView: View {
    let onStart: ([String], GameSettings) -> Void

    @State private var players: [String] = []
    @State private var newName = ""
    @State private var settings = GameSettings()
    @State private var showRules = false
    @FocusState private var nameFieldFocused: Bool

    private var canStart: Bool { players.count >= 2 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 6) {
                        Text("☠ DEATHBOX ☠")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.gold)
                        Text("Higher or lower. Three in a row or you drink.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(Array(players.enumerated()), id: \.offset) { index, name in
                        HStack {
                            Text("\(index + 1).").foregroundStyle(.secondary).monospacedDigit()
                            Text(name)
                        }
                    }
                    .onDelete { players.remove(atOffsets: $0) }
                    .onMove { players.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("Add a player", text: $newName)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .focused($nameFieldFocused)
                            .onSubmit(addPlayer)
                        Button(action: addPlayer) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                } header: {
                    Text("Players (in turn order)")
                } footer: {
                    Text(canStart ? "Swipe to remove. Press Edit to reorder." : "Add at least 2 players.")
                }

                Section("House rules") {
                    Toggle("Aces are high", isOn: $settings.aceHigh)
                    Picker("Ties", selection: $settings.tieRule) {
                        ForEach(TieRule.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Correct calls to pass: \(settings.streakToPass)",
                            value: $settings.streakToPass, in: 1...6)
                }

                Section {
                    Button {
                        onStart(players, settings)
                    } label: {
                        Text("Deal the cards")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canStart)
                } footer: {
                    Text("Please drink responsibly. Swap in water or soda any time.")
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton().disabled(players.isEmpty) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showRules = true } label: { Label("Rules", systemImage: "questionmark.circle") }
                }
            }
            .sheet(isPresented: $showRules) { RulesView() }
        }
    }

    private var trimmedName: String { newName.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func addPlayer() {
        guard !trimmedName.isEmpty else { return }
        players.append(trimmedName)
        newName = ""
        nameFieldFocused = true
    }
}

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    rule("1", "The box", "16 cards are dealt face up in a 4×4 grid. Each card is the top of a stack. The rest of the deck is the draw pile.")
                    rule("2", "Your turn", "Point at any stack and call whether the next card off the deck will be higher or lower than the top card. The new card goes on that stack.")
                    rule("3", "Three in a row", "Get 3 correct calls in a row and the turn passes to the next player.")
                    rule("4", "Wrong call", "Count the cards in that stack. You drink while everyone else takes turns counting out loud, one number each, up to that number.")
                    rule("5", "Beat the count", "If you finish your drink before they reach the number, whoever was up to say the next number drinks for the rest of the count.")
                    rule("6", "Deck runs out", "Whoever's turn it is picks a row or column to remove. Those cards are shuffled into the new draw pile, and the box gets smaller.")
                    rule("7", "Game over", "When the last row or column is removed, the box is dead.")
                }
                .padding()
            }
            .navigationTitle("How to play")
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    private func rule(_ n: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n)
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.blood))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SetupView { _, _ in }
}
