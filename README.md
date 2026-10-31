# Deathbox
Iphone app version of the drinking game Deathbox. Created by me and claude

A SwiftUI iPhone app for passing around the table. No accounts, no internet, just the box.

## How to play

1. **The box** – 16 cards are dealt face up in a 4×4 grid. Each card is the top of a stack; the rest of the deck is the draw pile.
2. **Your turn** – Tap a stack, then call **Higher** or **Lower**. The next card from the deck lands on that stack.
3. **Three in a row** – Get 3 correct calls in a row and the turn passes to the next player.
4. **Wrong call** – The app counts the cards in that stack. You drink while everyone else takes turns counting out loud, one number each, up to that number. Tap the big number every time someone says one; the app shows who's up next.
5. **Beat the count** – If you finish your drink before they're done, tap **finished the drink**. Whoever was up to say the next number drinks for the rest of the count.
6. **Deck runs out** – Whoever's turn it is taps an ✕ to remove a row or column. Those cards get shuffled into the new deck and the box shrinks.
7. **Game over** – When the last row or column is gone, the box is dead. The app shows who made the most wrong calls.

### House rules (set before dealing)
- Aces high or low
- Ties count as wrong (default) or correct
- How many correct calls in a row to pass the turn (default 3)

A wrong call resets your streak, and you keep going until you get 3 in a row.

## Running it on your iPhone

You need a Mac with **Xcode 16 or newer** (free from the Mac App Store).

1. Clone or download this repo and open `Deathbox.xcodeproj`.
2. In Xcode, click the **Deathbox** project → **Signing & Capabilities** → pick your Apple ID under **Team** (add it in Xcode → Settings → Accounts if needed). If the bundle ID is taken, change `com.ktmax89.deathbox` to something unique.
3. Plug in your iPhone, select it at the top of Xcode, and press **Run** (▶).
4. First time only: on the iPhone, go to **Settings → General → VPN & Device Management** and trust your developer certificate. You may also need to turn on **Developer Mode** (Settings → Privacy & Security).

With a free Apple ID the app works for 7 days before you need to re-run it from Xcode. A paid Apple Developer account ($99/yr) removes that limit and lets you share it through TestFlight.

## Project layout

```
Deathbox/
  DeathboxApp.swift        App entry, theme colors
  Model/Card.swift         Cards and deck
  Model/GameEngine.swift   All game rules (grid, calls, streaks, penalties, elimination)
  Views/SetupView.swift    Players + house rules, and the rules sheet
  Views/GameView.swift     The 4×4 box, Higher/Lower, row/column elimination, game over
  Views/PenaltyView.swift  Drink-and-count screen
  Views/CardView.swift     Card faces and backs
```

Requires iOS 17+. Please drink responsibly; water or soda works just as well.
