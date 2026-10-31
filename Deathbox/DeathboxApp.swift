import SwiftUI

@main
struct DeathboxApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var game: GameEngine?

    var body: some View {
        ZStack {
            Theme.felt.ignoresSafeArea()
            if let game {
                GameView(game: game, onQuit: { withAnimation { self.game = nil } })
                    .transition(.move(edge: .trailing))
            } else {
                SetupView { players, settings in
                    withAnimation { game = GameEngine(players: players, settings: settings) }
                }
                .transition(.move(edge: .leading))
            }
        }
    }
}

enum Theme {
    static let felt = LinearGradient(
        colors: [Color(red: 0.05, green: 0.30, blue: 0.17), Color(red: 0.02, green: 0.16, blue: 0.09)],
        startPoint: .top, endPoint: .bottom)
    static let blood = Color(red: 0.80, green: 0.10, blue: 0.15)
    static let gold = Color(red: 0.98, green: 0.78, blue: 0.25)
    static let good = Color(red: 0.20, green: 0.80, blue: 0.40)
}
